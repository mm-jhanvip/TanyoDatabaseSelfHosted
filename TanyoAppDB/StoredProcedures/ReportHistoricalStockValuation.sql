/*
EXEC ReportHistoricalStockValuation
    @TenantId = 2
    ,@Date = '2026-04-14'
	,@CategoryId = NULL
    ,@ProductTitle = NULL
    ,@ModelNo = NULL
    ,@PageIndex = 1
    ,@PageSize = 100
    ,@SortBy = 'CategoryName'
    ,@SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[ReportHistoricalStockValuation] (
	@TenantId INT 
	,@Date DATE
	,@CategoryId BIGINT = NULL
	,@ProductTitle VARCHAR(255) = NULL
	,@ModelNo VARCHAR(100) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'CategoryName'
	,@SortOrder VARCHAR(10) = 'ASC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @FromDateTime DATETIMEOFFSET
		,@ToDateTime DATETIMEOFFSET;

	IF (@Date IS NOT NULL)
	BEGIN
		SET @FromDateTime = CAST(CAST(@Date AS VARCHAR(128)) + ' 00:00:00.0000001 +05:30' AS DATETIMEOFFSET) ;
		SET @ToDateTime = CAST(CAST(@Date AS VARCHAR(128)) + ' 23:59:59.9999999 +05:30' AS DATETIMEOFFSET);
	END

	;WITH CTE
	AS
	(
	SELECT CT.CategoryName
		,DSV.CategoryId
		,ImagePath AS ProductImage
		,PT.ProductTitle
		,PT.ModelNo
		,ActualStock AS StockOnHand
		,ValuationOfActualStock AS TotalCostPrice
		,ValuationOfRetailStock AS TotalRetailPrice
		,ValuationOfWholesaleStock AS TotalWholesalePrice
		,DSV.CreatedDate
		,COUNT(*) OVER () AS TotalCount
		,SUM(ActualStock) OVER () AS GrandTotalStockOnHand
		,SUM(ValuationOfActualStock) OVER () AS GrandTotalCostPrice
		,SUM(ValuationOfRetailStock) OVER () AS GrandTotalRetailPrice
		,SUM(ValuationOfWholesaleStock) OVER () AS GrandTotalWholesalePrice
	FROM [DailyStockValuation] DSV WITH (NOLOCK)
	INNER JOIN Products PT WITH (NOLOCK) ON PT.ProductId = DSV.ProductId 
	INNER JOIN Categories CT WITH (NOLOCK) ON CT.CategoryId = PT.CategoryId
	WHERE PT.Status <> 3
	AND CT.IsDeleted = 0
	AND PT.TenantId = @TenantId
	AND
		(
			@CategoryId IS NULL
			OR CT.CategoryId = @CategoryId
			)
		AND (
			@ProductTitle IS NULL
			OR PT.ProductTitle LIKE '%' + @ProductTitle + '%'
			)
		AND (
			@ModelNo IS NULL
			OR PT.ModelNo LIKE '%' + @ModelNo + '%'
			)
		AND (
			@Date IS NULL
			OR (
				DSV.ReportDate >= @FromDateTime
				AND DSV.ReportDate <= @ToDateTime
				)
			)
	ORDER BY CASE 
			WHEN @SortBy = 'CategoryName'
				AND @SortOrder = 'ASC'
				THEN CT.CategoryName
			END ASC
		,CASE 
			WHEN @SortBy = 'CategoryName'
				AND @SortOrder = 'DESC'
				THEN CT.CategoryName
			END DESC
		,CASE 
			WHEN @SortBy = 'ProductTitle'
				AND @SortOrder = 'ASC'
				THEN PT.ProductTitle
			END ASC
		,CASE 
			WHEN @SortBy = 'ProductTitle'
				AND @SortOrder = 'DESC'
				THEN PT.ProductTitle
			END DESC
		,CASE 
			WHEN @SortBy = 'ModelNo'
				AND @SortOrder = 'ASC'
				THEN PT.ModelNo
			END ASC
		,CASE 
			WHEN @SortBy = 'ModelNo'
				AND @SortOrder = 'DESC'
				THEN PT.ModelNo
			END DESC
		,CASE 
			WHEN @SortBy = 'StockOnHand'
				AND @SortOrder = 'ASC'
				THEN ActualStock
			END ASC
		,CASE 
			WHEN @SortBy = 'StockOnHand'
				AND @SortOrder = 'DESC'
				THEN ActualStock
			END DESC
		,CASE 
			WHEN @SortBy = 'TotalCostPrice'
				AND @SortOrder = 'ASC'
				THEN ValuationOfActualStock
			END ASC
		,CASE 
			WHEN @SortBy = 'TotalCostPrice'
				AND @SortOrder = 'DESC'
				THEN ValuationOfActualStock
			END DESC
		,CASE 
			WHEN @SortBy = 'TotalRetailPrice'
				AND @SortOrder = 'ASC'
				THEN ValuationOfRetailStock
			END ASC
		,CASE 
			WHEN @SortBy = 'TotalRetailPrice'
				AND @SortOrder = 'DESC'
				THEN ValuationOfRetailStock
			END DESC
		,CASE 
			WHEN @SortBy = 'TotalWholesalePrice'
				AND @SortOrder = 'ASC'
				THEN ValuationOfWholesaleStock
			END ASC
		,CASE 
			WHEN @SortBy = 'TotalWholesalePrice'
				AND @SortOrder = 'DESC'
				THEN ValuationOfWholesaleStock
			END DESC
		,CASE 
			WHEN @SortBy = 'CreatedDate'
				AND @SortOrder = 'ASC'
				THEN DSV.CreatedDate
			END ASC
		,CASE 
			WHEN @SortBy = 'CreatedDate'
				AND @SortOrder = 'DESC'
				THEN DSV.CreatedDate
			END DESC,
            DSV.DailyStockValuationId ASC

			OFFSET(@PageIndex - 1) * @PageSize ROWS

	FETCH NEXT @PageSize ROWS ONLY
	)
	SELECT *
		,SUM(StockOnHand) OVER () AS StockOnHandTotal
		,SUM(TotalCostPrice) OVER () AS CostPriceTotal
		,SUM(TotalRetailPrice) OVER () AS RetailPriceTotal
		,SUM(TotalWholesalePrice) OVER () AS WholesalePriceTotal
	FROM CTE
	END TRY
	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg
	END CATCH
END

GO

