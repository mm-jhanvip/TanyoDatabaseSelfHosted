/*
	EXEC [dbo].[ListPORawMaterialsByVendorId]
		@TenantId = 2
		,@VendorId = 13
		,@PONumber = NULL
*/
CREATE   PROCEDURE [dbo].[ListPORawMaterialsByVendorId]
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
		
		SELECT prm.PORawMaterialId AS ID
			,prm.PONumber AS PONumber
		FROM PORawMaterials prm
		INNER JOIN PORawMaterialItems prmi ON prm.PORawMaterialId = prmi.PORawMaterialId
		LEFT JOIN (
			SELECT 
				rmie.PONumber,
				rmide.RawMaterialId,
				SUM(rmide.Quantity) AS TotalInwardQty
			FROM RawMaterialInwardEntry rmie
			INNER JOIN RawMaterialInwardDetailsEntry rmide ON rmie.InwardId = rmide.InwardId
			WHERE rmie.IsDeleted = 0
			GROUP BY rmie.PONumber, rmide.RawMaterialId
		) AS inward ON inward.PONumber = prm.PONumber AND inward.RawMaterialId = prmi.RawMaterialId
		WHERE prm.VendorId = @VendorId
		  AND prm.TenantID = @TenantId
		  AND LTRIM(RTRIM(prm.PONumber)) <> ''
		  AND (
			  inward.TotalInwardQty IS NULL 
			  OR inward.TotalInwardQty < prmi.Quantity
		  )
		  AND (
			  @PONumber IS NULL 
			  OR LTRIM(RTRIM(LOWER(prm.PONumber))) LIKE '%' + LTRIM(RTRIM(LOWER(@PONumber))) + '%'
		  )
		GROUP BY prm.PORawMaterialId, prm.PONumber
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

