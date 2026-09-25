/*
	EXEC [dbo].[GetPOProductItemsById]
		@TenantId = 2
		,@POProductId = 2
*/
CREATE   PROCEDURE [dbo].[GetPOProductItemsById]
(
	@TenantId INT
    ,@POProductId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @OtherWarehouseId BIGINT

		SELECT @OtherWarehouseId = Id
		FROM Warehouse WITH (NOLOCK)
		WHERE TenantId = @TenantId
			AND IsDeleted = 0
			AND Name = 'Other'

		;WITH InwardBase AS (
			SELECT ie.InwardId
			FROM InwardEntry AS ie WITH(NOLOCK)
			WHERE ie.POProductId = @POProductId 
			AND ie.IsDeleted = 0
		),
		-- 3. Inward Quantities per Product
		InwardedQty AS (
			SELECT ide.ProductId, SUM(ide.Quantity) AS TotalInwardQty
			FROM InwardDetailsEntry AS ide WITH(NOLOCK)
			INNER JOIN InwardBase AS ib WITH(NOLOCK) ON ide.InwardId = ib.InwardId
			WHERE ide.IsDeleted = 0
			GROUP BY ide.ProductId
		),
		-- 4. Final product list (filtered)
		ProductList AS (
			SELECT 
				p.ProductId AS Id
				,p.ProductTitle AS Title
				,p.ModelNo AS Number
				,CAST(
					CASE 
						WHEN iq.TotalInwardQty IS NULL THEN bii.Quantity
						ELSE bii.Quantity - iq.TotalInwardQty
					END AS Numeric(18,2)
				) AS Quantity
				,p.CoverImage
				,CAST(
					CASE WHEN c.CategoryTypeId = 2
						THEN 1
					ELSE 0 
					END AS BIT
				) AS IsFabric
				,COALESCE(prevWarehouse.PreviousWarehouseId, @OtherWarehouseId) AS PreviousWarehouseId
			FROM POProductItems AS bii WITH(NOLOCK)
			INNER JOIN Products AS p WITH(NOLOCK) ON p.ProductId = bii.ProductID
			INNER JOIN Categories AS c WITH(NOLOCK) ON p.CategoryId = c.CategoryId
			LEFT JOIN InwardedQty AS iq WITH(NOLOCK) ON iq.ProductId = bii.ProductID
			OUTER APPLY (
					SELECT TOP 1 ide.WarehouseId AS PreviousWarehouseId
					FROM InwardDetailsEntry AS ide WITH (NOLOCK)
					INNER JOIN InwardEntry AS ie WITH (NOLOCK) ON ide.InwardId = ie.InwardId
					WHERE ide.ProductId = p.ProductId
						AND ide.IsDeleted = 0
						AND ie.IsDeleted = 0
						AND ie.TenantId = @TenantId
						AND ide.WarehouseId IS NOT NULL
						AND ide.WarehouseId > 0
					ORDER BY ie.CreatedDate DESC
					) AS prevWarehouse
			WHERE bii.POProductId = @POProductId
			  AND p.Status = 1  -- Published
			  AND (iq.TotalInwardQty IS NULL OR bii.Quantity - iq.TotalInwardQty > 0)
		)

		-- 5. Select with pagination + total count
		SELECT 
			Id
			,Title
			,Number
			,Quantity
			,CoverImage
			,IsFabric
			,PreviousWarehouseId
		FROM ProductList
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

