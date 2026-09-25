-- =============================================
-- Author		: Kishan Kalena
-- Create date	: 31-05-2024
-- Description	: [StockValuationReport]
-- =============================================
/*
	EXEC [dbo].[StockValuationReport]
		@TenantId = 1
		,@ProductTitle = null
		,@ModelNo = null
		,@CategoryId = NULL
		,@PageIndex = '1'
		,@PageSize = '100'
		,@SortBy = 'ValuationOfWholesaleStock'
		,@SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[StockValuationReport] (
	@TenantId INT
	,@ProductTitle VARCHAR(100) = ''
	,@ModelNo VARCHAR(100) = ''
	,@CategoryId BIGINT = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'ProductTitle'
	,@SortOrder VARCHAR(50) = 'ASC'
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;

		DECLARE @ProductSubjectTypeId INT;

		SELECT @ProductSubjectTypeId = SubjectTypeId
		FROM SubjectTypes
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		WITH CTE
		AS (
			SELECT p.ProductId
				,P.CoverImage AS ImagePath
				,p.ProductTitle AS ProductTitle
				,ia.Quantity AS ActualStock
				,c1.CategoryName AS CategoryName
				,c1.CategoryId AS CategoryId
				,p.ModelNo AS ModelNo
				,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
				,CAST(p.CostPrice * ia.Quantity AS NUMERIC(18, 2)) AS ValuationOfActualStock
				,CAST(p.RetailerPrice * ia.Quantity AS NUMERIC(18, 2)) AS ValuationOfRetailStock
				,CAST(p.WholesalerPrice * ia.Quantity AS NUMERIC(18, 2)) AS ValuationOfWholesaleStock
				,SUM(ia.Quantity) OVER () AS GrandTotalActualStock
				,SUM(CAST(p.CostPrice * ia.Quantity AS NUMERIC(18, 2))) OVER () AS GrandTotalValuationOfActualStock
				,SUM(CAST(p.RetailerPrice * ia.Quantity AS NUMERIC(18, 2))) OVER () AS GrandTotalValuationOfRetailStock
				,SUM(CAST(p.WholesalerPrice * ia.Quantity AS NUMERIC(18, 2))) OVER () AS GrandTotalValuationOfWholesaleStock
			FROM ProductQuantities ia
			RIGHT JOIN Products p ON p.ProductId = ia.ProductId
			RIGHT JOIN Categories c1 ON p.CategoryId = c1.CategoryId
			RIGHT JOIN AspNetUsers users ON ia.LastModifiedBy = users.UserId
			--LEFT JOIN (
			--		SELECT TOP 1 *
			--		FROM ProductImages
			--		WHERE IsCover = 1
			--	) AS ProductImages ON p.ProductId = ProductImages.ProductId
			--OUTER APPLY (
			--	SELECT TOP 1 *
			--	FROM ProductImages
			--	WHERE p.ProductId = ProductImages.ProductId
			--	ORDER BY ProductImageID DESC
			--	) AS TopCoverImage
			WHERE p.TenantId = @TenantID
				AND c1.TenantId = @TenantId
				AND (
					@CategoryId IS NULL
					OR c1.CategoryId = @CategoryId
					)
				AND p.Status != 3
				AND c1.IsDeleted = 0
				AND (p.ProductTitle LIKE '%' + ISNULL(@ProductTitle, '') + '%')
				AND (p.ModelNo LIKE '%' + ISNULL(@ModelNo, '') + '%')
			GROUP BY p.ProductId
				,ia.Quantity
				,p.ProductTitle
				,c1.CategoryName
				,c1.CategoryId
				,p.ModelNo
				,p.CostPrice
				,p.RetailerPrice
				,p.WholesalerPrice
				,P.CoverImage
			ORDER BY CASE 
					WHEN @SortBy = 'ProductTitle'
						AND @SortOrder = 'ASC'
						THEN p.ProductTitle
					END ASC
				,CASE 
					WHEN @SortBy = 'ProductTitle'
						AND @SortOrder = 'DESC'
						THEN p.ProductTitle
					END DESC
				,CASE 
					WHEN @SortBy = 'ModelNo'
						AND @SortOrder = 'ASC'
						THEN p.ModelNo
					END ASC
				,CASE 
					WHEN @SortBy = 'ModelNo'
						AND @SortOrder = 'DESC'
						THEN p.ModelNo
					END DESC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'ASC'
						THEN c1.CategoryName
					END ASC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'DESC'
						THEN c1.CategoryName
					END DESC
				,CASE 
					WHEN @SortBy = 'ValuationOfActualStock'
						AND @SortOrder = 'ASC'
						THEN (p.CostPrice * ia.Quantity)
					END ASC
				,CASE 
					WHEN @SortBy = 'ValuationOfActualStock'
						AND @SortOrder = 'DESC'
						THEN (p.CostPrice * ia.Quantity)
					END DESC
				,CASE 
					WHEN @SortBy = 'ValuationOfRetailStock'
						AND @SortOrder = 'ASC'
						THEN (p.RetailerPrice * ia.Quantity)
					END ASC
				,CASE 
					WHEN @SortBy = 'ValuationOfRetailStock'
						AND @SortOrder = 'DESC'
						THEN (p.RetailerPrice * ia.Quantity)
					END DESC
				,CASE 
					WHEN @SortBy = 'ValuationOfWholesaleStock'
						AND @SortOrder = 'ASC'
						THEN (p.WholesalerPrice * ia.Quantity)
					END ASC
				,CASE 
					WHEN @SortBy = 'ValuationOfWholesaleStock'
						AND @SortOrder = 'DESC'
						THEN (p.WholesalerPrice * ia.Quantity)
					END DESC
				,CASE 
					WHEN @SortBy = 'ActualStock'
						AND @SortOrder = 'ASC'
						THEN (ia.Quantity)
					END ASC
				,CASE 
					WHEN @SortBy = 'ActualStock'
						AND @SortOrder = 'DESC'
						THEN (ia.Quantity)
					END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY
			)
		SELECT *
			,SUM(ActualStock) OVER () AS TotalActualStock
			,SUM(ValuationOfActualStock) OVER () AS TotalValuationOfActualStock
			,SUM(ValuationOfRetailStock) OVER () AS TotalValuationOfRetailStock
			,SUM(ValuationOfWholesaleStock) OVER () AS TotalValuationOfWholesaleStock
		FROM CTE
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END;

GO

