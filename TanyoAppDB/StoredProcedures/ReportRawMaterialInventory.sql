/*
EXEC ReportRawMaterialInventory
	@ProductId  = 94795
	,@Quantity  = 1
	,@PageIndex  = 1
	,@PageSize  = 100
	,@SortBy  = 'RequiredQuantity'
	,@SortOrder = 'DESC'
*/
CREATE PROCEDURE [dbo].[ReportRawMaterialInventory] (
	@ProductId BIGINT
	,@Quantity NUMERIC(18, 2)
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'RequiredQuantity'
	,@SortOrder VARCHAR(50) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		SELECT RM.RawMaterialId
			,RM.Title AS RawMaterialName
			,LKV.LookupValueName AS Unitname
			,PM.Qty AS QtyRequiredPerProduct
			,@Quantity AS ProductQuantity
			,(PM.Qty * @Quantity) AS RequiredQuantity
			,COUNT(*) OVER () AS TotalCount
		FROM ProductMaterials PM WITH (NOLOCK)
		INNER JOIN Products PT WITH (NOLOCK) ON PM.ProductId = PT.ProductId
		INNER JOIN RawMaterials RM WITH (NOLOCK) ON RM.RawMaterialId = PM.SubjectId
		INNER JOIN SubjectTypes ST WITH (NOLOCK) ON PM.SubjectTypeId = ST.SubjectTypeId
			AND ST.SubjectTypeName = 'RawMaterials'
		INNER JOIN LookupValues LKV WITH (NOLOCK) ON LKV.LookupValueId = RM.UnitId
		WHERE PM.ProductId = @ProductId
		ORDER BY CASE 
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
				WHEN @SortBy = 'QtyRequiredPerProduct'
					AND @SortOrder = 'ASC'
					THEN PM.Qty
				END ASC
			,CASE 
				WHEN @SortBy = 'QtyRequiredPerProduct'
					AND @SortOrder = 'DESC'
					THEN PM.Qty
				END DESC
			,CASE 
				WHEN @SortBy = 'RequiredQuantity'
					AND @SortOrder = 'ASC'
					THEN PM.Qty * @Quantity
				END ASC
			,CASE 
				WHEN @SortBy = 'RequiredQuantity'
					AND @SortOrder = 'DESC'
					THEN PM.Qty * @Quantity
				END DESC
			,CASE 
				WHEN @SortBy = 'Unitname'
					AND @SortOrder = 'ASC'
					THEN LKV.LookupValueName
				END ASC
			,CASE 
				WHEN @SortBy = 'Unitname'
					AND @SortOrder = 'DESC'
					THEN LKV.LookupValueName
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY
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

