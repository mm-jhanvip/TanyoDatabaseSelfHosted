/*
EXEC dbo.GetUnMappedProducts
	@POProductId = 40925,
    @VendorId = 10153,
    @TenantId = 2
*/

CREATE  PROCEDURE [dbo].[GetUnMappedProducts]
(
    @TenantId BIGINT,
    @POProductId BIGINT,
    @VendorId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
           @VendorId AS VendorId,
            P.ProductId,
            P.ProductTitle,
            P.ModelNo,
            PPI.VendorModelNo,
            PPI.UnitPrice AS VendorProductPrice,
            PPI.POProductId,
            PPI.POProductItemId
        FROM Products P WITH (NOLOCK)
        INNER JOIN POProductItems PPI WITH (NOLOCK)
            ON PPI.ProductId = P.ProductId
           AND PPI.POProductId = @POProductId
        LEFT JOIN ProductVendorMapping PVM WITH (NOLOCK)
            ON PVM.ProductId = P.ProductId
           AND PVM.VendorId = @VendorId
           AND PVM.IsDeleted = 0
        WHERE P.TenantId = @TenantId
          AND PVM.ProductId IS NULL
        ORDER BY P.ProductTitle;
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
END;

GO

