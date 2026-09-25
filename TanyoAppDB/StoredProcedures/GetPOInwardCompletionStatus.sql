CREATE     PROCEDURE [dbo].[GetPOInwardCompletionStatus]
(
    @TenantId INT,
    @POProductId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ;WITH InwardBase AS (
            SELECT ie.InwardId
            FROM InwardEntry ie
            WHERE ie.POProductId = @POProductId
              AND ie.IsDeleted = 0
              AND ie.TenantId = @TenantId
        ),
        InwardedQty AS (
            SELECT 
                ide.ProductId,
                SUM(ide.Quantity) AS TotalInwardQty
            FROM InwardDetailsEntry ide
            INNER JOIN InwardBase ib ON ide.InwardId = ib.InwardId
            WHERE ide.IsDeleted = 0
            GROUP BY ide.ProductId
        )
        SELECT 
            pii.POProductItemId,
            pii.ProductId,
            pii.Quantity AS POQty,
            ISNULL(iq.TotalInwardQty, 0) AS TotalInwardQty,
            CAST(
                CASE 
                    WHEN ISNULL(iq.TotalInwardQty, 0) >= pii.Quantity 
                        THEN 1 
                    ELSE 0 
                END
            AS BIT) AS IsCompleted
        FROM POProductItems pii
        LEFT JOIN InwardedQty iq ON iq.ProductId = pii.ProductId
        WHERE pii.POProductId = @POProductId

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT,
                @ObjectName VARCHAR(500);

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ObjectName = OBJECT_NAME(@@PROCID);

        EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

GO

