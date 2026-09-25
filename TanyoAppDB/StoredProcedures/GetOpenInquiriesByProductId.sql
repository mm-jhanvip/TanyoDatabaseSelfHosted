/*  
    EXEC dbo.GetOpenInquiriesByProductId
        @TenantId = 125
        ,@ProductId = 97589
*/
CREATE PROCEDURE [dbo].[GetOpenInquiriesByProductId]
(
    @TenantId INT
    ,@ProductId BIGINT = NULL
    ,@CategoryId BIGINT = NULL
)
WITH ENCRYPTION
AS
BEGIN   
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT DISTINCT o.OrderId
        FROM Orders o WITH (NOLOCK)
        INNER JOIN OrderSetItems osi WITH (NOLOCK) ON osi.OrderId = o.OrderId
            AND osi.IsDeleted = 0
        INNER JOIN Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
        WHERE o.TenantId = @TenantId
        AND o.Status IN (0, 1) --Inquiry, Pending For Approval
        AND o.IsArchive = 0
        AND (@ProductId IS NULL OR osi.SubjectId = @ProductId)
        AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId)

    END TRY
    BEGIN CATCH
        DECLARE
            @ObjectName VARCHAR(500),
            @ErrorMsg VARCHAR(MAX);

        SET @ObjectName = OBJECT_NAME(@@PROCID);
        SET @ErrorMsg = ERROR_MESSAGE();

        EXEC dbo.SaveDBErrorLog
            @ObjectName = @ObjectName,
            @ErrorMsg = @ErrorMsg;
    END CATCH
END

GO

