CREATE PROCEDURE [dbo].[ReportMaterialReadyPOItems] (
	@TenantId INT
	,@VendorId BIGINT = NULL
	,@POItemMaterialReadyFromDate DATE = NULL
	,@POItemMaterialReadyToDate DATE = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@SortBy VARCHAR(50) = 'TotalQuantity'
	,@SortOrder VARCHAR(10) = 'DESC'
	,@VendorLocation NVARCHAR(100) = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		WITH FilteredData
		AS (
			SELECT V.VendorId
				,V.VendorName
				,PT.ProductId
				,PT.ProductTitle
				,PO.POProductId
				,PO.PONumber
				,PO.OrderDate
				,PO.ExpectedDeliveryDate
				,POI.POProductItemId
				,POI.Quantity
				,POI.Status AS POItemStatus
				,CASE 
					WHEN POI.Status = 1
						THEN 'Pending'
					WHEN POI.Status = 2
						THEN 'Approved'
					WHEN POI.Status = 3
						THEN 'Cancelled'
					WHEN POI.Status = 4
						THEN 'Completed'
					WHEN POI.Status = 5
						THEN 'MaterialReady'
					ELSE ''
					END AS POItemStatusName
				,POI.POItemMaterialReadyDate AS MaterialReadyDate
				,POI.TentativePOItemPickupDate AS PickupDate
			FROM POProducts PO WITH (NOLOCK)
			INNER JOIN POProductItems POI WITH (NOLOCK) ON PO.POProductId = POI.POProductId
			INNER JOIN Products PT WITH (NOLOCK) ON PT.ProductId = POI.ProductId
			INNER JOIN Vendors V WITH (NOLOCK) ON V.VendorId = PO.VendorId
			WHERE PO.TenantId = @TenantId
				AND PO.IsDeleted = 0
				AND POI.Status = 5
				AND (
					@VendorId IS NULL
					OR PO.VendorId = @VendorId
					)
				AND (
					@POItemMaterialReadyFromDate IS NULL
					OR CAST(POI.POItemMaterialReadyDate AS DATE) >= @POItemMaterialReadyFromDate
					)
				AND (
					@POItemMaterialReadyToDate IS NULL
					OR CAST(POI.POItemMaterialReadyDate AS DATE) <= @POItemMaterialReadyToDate
					)
				AND (
					@VendorLocation IS NULL
					OR EXISTS (
						SELECT 1
						FROM VendorAddresses VA
						WHERE VA.VendorId = V.VendorId
							AND VA.City = @VendorLocation
							AND VA.IsDeleted = 0
						)
					)
			)
		SELECT FD.VendorId
			,FD.VendorName
			,FD.ProductId
			,FD.ProductTitle
			,SUM(FD.Quantity) AS TotalQuantity
			,(
				SELECT FD2.POProductId
					,FD2.PONumber
					,FD2.OrderDate
					,FD2.ExpectedDeliveryDate
					,FD2.POProductItemId
					,FD2.POItemStatus
					,FD2.POItemStatusName
					,FD2.Quantity
					,FD2.MaterialReadyDate
					,FD2.PickupDate
				FROM FilteredData FD2
				WHERE FD2.VendorId = FD.VendorId
					AND FD2.ProductId = FD.ProductId
				ORDER BY FD2.MaterialReadyDate DESC
				FOR JSON PATH
					,INCLUDE_NULL_VALUES
				) AS Details
			,COUNT(*) OVER () AS TotalCount
		FROM FilteredData FD
		GROUP BY FD.VendorId
			,FD.VendorName
			,FD.ProductId
			,FD.ProductTitle
		ORDER BY CASE 
				WHEN @SortBy = 'VendorName'
					AND @SortOrder = 'ASC'
					THEN FD.VendorName
				END ASC
			,CASE 
				WHEN @SortBy = 'VendorName'
					AND @SortOrder = 'DESC'
					THEN FD.VendorName
				END DESC
			,CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'ASC'
					THEN FD.ProductTitle
				END ASC
			,CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'DESC'
					THEN FD.ProductTitle
				END DESC
			,CASE 
				WHEN @SortBy = 'TotalQuantity'
					AND @SortOrder = 'ASC'
					THEN SUM(FD.Quantity)
				END ASC
			,CASE 
				WHEN @SortBy = 'TotalQuantity'
					AND @SortOrder = 'DESC'
					THEN SUM(FD.Quantity)
				END DESC
			,FD.VendorName
			,FD.ProductTitle OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMsg NVARCHAR(4000)
		DECLARE @ObjectName VARCHAR(500);

		SELECT @ErrorMsg = ERROR_MESSAGE()
			,@ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

