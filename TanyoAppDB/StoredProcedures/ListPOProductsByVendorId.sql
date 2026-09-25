/*
	EXEC [dbo].[ListPOProductsByVendorId]
		@TenantId = 2
		,@VendorId = 13
		,@PONumber = NULL
*/
CREATE   PROCEDURE [dbo].[ListPOProductsByVendorId]
(
	@TenantId INT
    ,@VendorId BIGINT
    ,@PONumber NVARCHAR(100) = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
		
		SELECT po.POProductId AS ID
			,po.PONumber AS PONumber
		FROM POProducts po
		INNER JOIN POProductItems poi ON po.POProductId = poi.POProductId
		LEFT JOIN (
			SELECT 
				rmie.PONumber,
				rmide.ProductId,
				SUM(rmide.Quantity) AS TotalInwardQty
			FROM InwardEntry rmie
			INNER JOIN InwardDetailsEntry rmide ON rmie.InwardId = rmide.InwardId
			WHERE rmie.IsDeleted = 0
			GROUP BY rmie.PONumber, rmide.ProductId
		) AS inward ON inward.PONumber = po.PONumber AND inward.ProductId = poi.ProductId
		WHERE po.VendorId = @VendorId
		  AND po.TenantID = @TenantId
		  AND LTRIM(RTRIM(po.PONumber)) <> ''
		  AND (
			  inward.TotalInwardQty IS NULL 
			  OR inward.TotalInwardQty < poi.Quantity
		  )
		  AND (
			  @PONumber IS NULL 
			  OR LTRIM(RTRIM(LOWER(po.PONumber))) LIKE '%' + LTRIM(RTRIM(LOWER(@PONumber))) + '%'
		  )
		  AND po.Status in (2,5) -- approved 2, material ready 5.
		GROUP BY po.POProductId, po.PONumber
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState)
	END CATCH
END

GO

