/*
EXEC [dbo].[ReportRawMaterialIssue]
    @TenantId = 2,
    @RawMaterialName = NULL,
    @OrderNo = 'R00644-11052026',
    @IssuedFromDate = NULL,
    @IssuedToDate = NULL,
    @PageIndex = 1,
    @PageSize = 20,
    @SortBy = 'ProvidedQty',
    @SortOrder = 'DESC'
*/
CREATE PROCEDURE [dbo].[ReportRawMaterialIssue] (
	@TenantId INT
	,@RawMaterialName VARCHAR(50) = NULL
	,@OrderNo VARCHAR(20) = NULL
	,@IssuedFromDate DATE = NULL
	,@IssuedToDate DATE = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 20
	,@SortBy VARCHAR(50) = 'ProvidedQty'
	,@SortOrder VARCHAR(4) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DROP TABLE IF EXISTS #RawMaterials;

			SELECT MWD.RawMaterialId
				,SUM(CASE 
						WHEN ISNULL(MWD.IsNotNeeded, 0) = 1
							THEN 0
						WHEN MWD.RequiredQty IS NULL
							THEN 0
						ELSE MWD.RequiredQty
						END) AS RequiredQty
				,SUM(ISNULL(MWD.ProvidedQty, 0)) AS ProvidedQty
			INTO #RawMaterials
			FROM ManufacturingWorkOrderDetails MWD WITH (NOLOCK)
			INNER JOIN RawMaterials RM WITH (NOLOCK) ON MWD.RawMaterialId = RM.RawMaterialId
				AND RM.TenantId = @TenantId
			INNER JOIN ManufacturingWorkOrders MWO WITH (NOLOCK) ON MWO.ManufacturingWorkOrderId = MWD.ManufacturingWorkOrderId
			INNER JOIN Orders ORD WITH (NOLOCK) ON ORD.OrderId = MWO.OrderId
			INNER JOIN OrderSetItems OSI WITH (NOLOCK) ON OSI.OrderSetItemId = MWO.OrderSetItemId
				AND OSI.IsDeleted = 0
			WHERE ISNULL(MWO.IsDeleted, 0) = 0
				AND (
					@RawMaterialName IS NULL
					OR RM.Title LIKE '%' + @RawMaterialName + '%'
					)
				AND (
					@OrderNo IS NULL
					OR ORD.OrderNo LIKE '%' + @OrderNo + '%'
					)
				AND (
					ISNULL(MWD.ProvidedQty, 0) > 0
					OR ISNULL(MWD.IsNotNeeded, 0) = 1
					)
				AND (
					(
						@IssuedFromDate IS NULL
						AND @IssuedToDate IS NULL
						)
					OR EXISTS (
						SELECT 1
						FROM ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK)
						WHERE MWML.ManufacturingWorkOrderDetailId = MWD.ManufacturingWorkOrderDetailId
							AND MWML.RawMaterialId = MWD.RawMaterialId
							AND (
								@IssuedFromDate IS NULL
								OR CAST(MWML.CreatedDate AS DATE) >= @IssuedFromDate
								)
							AND (
								@IssuedToDate IS NULL
								OR CAST(MWML.CreatedDate AS DATE) <= @IssuedToDate
								)
						)
					)
			GROUP BY MWD.RawMaterialId;

		SELECT RM.RawMaterialId
			,RM.Title AS RawMaterialName
			,RMI.Inventory
			,RMS.ProvidedQty
			,RMS.RequiredQty
			,(
				SELECT MAX(MWML.CreatedDate)
				FROM ManufacturingWorkOrderDetails MWOD_I WITH (NOLOCK)
				INNER JOIN ManufacturingWorkOrders MWO_I WITH (NOLOCK) ON MWO_I.ManufacturingWorkOrderId = MWOD_I.ManufacturingWorkOrderId
				INNER JOIN Orders ORD_I WITH (NOLOCK) ON ORD_I.OrderId = MWO_I.OrderId
				INNER JOIN ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK) ON MWML.ManufacturingWorkOrderDetailId = MWOD_I.ManufacturingWorkOrderDetailId
					AND MWML.RawMaterialId = MWOD_I.RawMaterialId
				WHERE ISNULL(MWO_I.IsDeleted, 0) = 0
					AND MWOD_I.RawMaterialId = RM.RawMaterialId
					AND (
						@OrderNo IS NULL
						OR ORD_I.OrderNo LIKE '%' + @OrderNo + '%'
						)
					AND (
						@IssuedFromDate IS NULL
						OR CAST(MWML.CreatedDate AS DATE) >= @IssuedFromDate
						)
					AND (
						@IssuedToDate IS NULL
						OR CAST(MWML.CreatedDate AS DATE) <= @IssuedToDate
						)
				) AS IssuedDate
			,(
				SELECT ORD.OrderNo
					,MWOD.RequiredQty
					,MWOD.ProvidedQty
					,MWOD.ManufacturingWorkOrderDetailId
					,CAST(ISNULL(MWOD.IsFromBom, 1) AS BIT) AS IsFromBom
					,CAST(ISNULL(MWOD.IsNotNeeded, 0) AS BIT) AS IsNotNeeded
					,(
						SELECT MAX(MWML.CreatedDate)
						FROM ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK)
						WHERE MWML.ManufacturingWorkOrderDetailId = MWOD.ManufacturingWorkOrderDetailId
							AND MWML.RawMaterialId = MWOD.RawMaterialId
							AND (
								@IssuedFromDate IS NULL
								OR CAST(MWML.CreatedDate AS DATE) >= @IssuedFromDate
								)
							AND (
								@IssuedToDate IS NULL
								OR CAST(MWML.CreatedDate AS DATE) <= @IssuedToDate
								)
						) AS IssuedDate
				FROM ManufacturingWorkOrderDetails MWOD WITH (NOLOCK)
				INNER JOIN ManufacturingWorkOrders MWO WITH (NOLOCK) ON MWO.ManufacturingWorkOrderId = MWOD.ManufacturingWorkOrderId
				INNER JOIN Orders ORD WITH (NOLOCK) ON ORD.OrderId = MWO.OrderId
				INNER JOIN OrderSetItems OSI WITH (NOLOCK) ON OSI.OrderSetItemId = MWO.OrderSetItemId
					AND OSI.IsDeleted = 0
				WHERE ISNULL(MWO.IsDeleted, 0) = 0
					AND MWOD.RawMaterialId = RM.RawMaterialId
					AND (
						@OrderNo IS NULL
						OR ORD.OrderNo LIKE '%' + @OrderNo + '%'
						)
					AND (
						ISNULL(MWOD.ProvidedQty, 0) > 0
						OR ISNULL(MWOD.IsNotNeeded, 0) = 1
						)
					AND (
						(
							@IssuedFromDate IS NULL
							AND @IssuedToDate IS NULL
							)
						OR EXISTS (
							SELECT 1
							FROM ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK)
							WHERE MWML.ManufacturingWorkOrderDetailId = MWOD.ManufacturingWorkOrderDetailId
								AND MWML.RawMaterialId = MWOD.RawMaterialId
								AND (
									@IssuedFromDate IS NULL
									OR CAST(MWML.CreatedDate AS DATE) >= @IssuedFromDate
									)
								AND (
									@IssuedToDate IS NULL
									OR CAST(MWML.CreatedDate AS DATE) <= @IssuedToDate
									)
							)
						)
				ORDER BY ORD.OrderNo
				FOR JSON PATH
				) AS ManufacturingWorkOrder
			,COUNT(1) OVER () AS TotalCount
		FROM RawMaterialInventory RMI WITH (NOLOCK)
		INNER JOIN RawMaterials RM WITH (NOLOCK) ON RMI.RawMaterialId = RM.RawMaterialId
			AND RM.TenantId = @TenantId
		INNER JOIN #RawMaterials RMS ON RM.RawMaterialId = RMS.RawMaterialId
		WHERE (
				@RawMaterialName IS NULL
				OR RM.Title LIKE '%' + @RawMaterialName + '%'
				)
			AND (
				RMS.ProvidedQty > 0
				OR EXISTS (
					SELECT 1
					FROM ManufacturingWorkOrderDetails MWOD2 WITH (NOLOCK)
					INNER JOIN ManufacturingWorkOrders MWO2 WITH (NOLOCK) ON MWO2.ManufacturingWorkOrderId = MWOD2.ManufacturingWorkOrderId
					WHERE MWOD2.RawMaterialId = RM.RawMaterialId
						AND ISNULL(MWO2.IsDeleted, 0) = 0
						AND ISNULL(MWOD2.IsNotNeeded, 0) = 1
					)
				)
		ORDER BY CASE 
				WHEN @SortBy = 'ProvidedQty'
					AND @SortOrder = 'ASC'
					THEN RMS.ProvidedQty
				END ASC
			,CASE 
				WHEN @SortBy = 'ProvidedQty'
					AND @SortOrder = 'DESC'
					THEN RMS.ProvidedQty
				END DESC
			,CASE 
				WHEN @SortBy = 'RawMaterialName'
					AND @SortOrder = 'ASC'
					THEN RM.Title
				END ASC
			,CASE 
				WHEN @SortBy = 'RawMaterialName'
					AND @SortOrder = 'DESC'
					THEN RM.Title
				END DESC
			,CASE 
				WHEN @SortBy = 'RequiredQty'
					AND @SortOrder = 'ASC'
					THEN RMS.RequiredQty
				END ASC
			,CASE 
				WHEN @SortBy = 'RequiredQty'
					AND @SortOrder = 'DESC'
					THEN RMS.RequiredQty
				END DESC
			,CASE 
				WHEN @SortBy = 'Inventory'
					AND @SortOrder = 'ASC'
					THEN RMI.Inventory
				END ASC
			,CASE 
				WHEN @SortBy = 'Inventory'
					AND @SortOrder = 'DESC'
					THEN RMI.Inventory
				END DESC
			,CASE 
				WHEN @SortBy = 'IssuedDate'
					AND @SortOrder = 'ASC'
					THEN (
							SELECT MAX(MWML.CreatedDate)
							FROM ManufacturingWorkOrderDetails MWOD_S WITH (NOLOCK)
							INNER JOIN ManufacturingWorkOrders MWO_S WITH (NOLOCK) ON MWO_S.ManufacturingWorkOrderId = MWOD_S.ManufacturingWorkOrderId
							INNER JOIN ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK) ON MWML.ManufacturingWorkOrderDetailId = MWOD_S.ManufacturingWorkOrderDetailId
								AND MWML.RawMaterialId = MWOD_S.RawMaterialId
							WHERE MWOD_S.RawMaterialId = RM.RawMaterialId
								AND ISNULL(MWO_S.IsDeleted, 0) = 0
							)
				END ASC
			,CASE 
				WHEN @SortBy = 'IssuedDate'
					AND @SortOrder = 'DESC'
					THEN (
							SELECT MAX(MWML.CreatedDate)
							FROM ManufacturingWorkOrderDetails MWOD_S WITH (NOLOCK)
							INNER JOIN ManufacturingWorkOrders MWO_S WITH (NOLOCK) ON MWO_S.ManufacturingWorkOrderId = MWOD_S.ManufacturingWorkOrderId
							INNER JOIN ManufacturingWorkOrderDetailsLog MWML WITH (NOLOCK) ON MWML.ManufacturingWorkOrderDetailId = MWOD_S.ManufacturingWorkOrderDetailId
								AND MWML.RawMaterialId = MWOD_S.RawMaterialId
							WHERE MWOD_S.RawMaterialId = RM.RawMaterialId
								AND ISNULL(MWO_S.IsDeleted, 0) = 0
							)
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

