
--SELECT * FROM dbo.UT_VW_IncorrectSQFTRetailerPrice
CREATE   VIEW [dbo].[UT_VW_IncorrectSQFTRetailerPrice]
WITH ENCRYPTION
AS
WITH SQFTProducts AS (
	SELECT p.TenantId
		,p.ProductId
		,p.CategoryId
		,c.CategoryName
		,p.ProductTitle
		,p.ModelNo
		,p.IsPriceAutoCalculated
		,c.RSPPercentage
		,c.WSPPercentage
		,pcf.CustomValue
		,p.CostPrice
		,p.RetailerPrice
		,CAST(ROUND(p.CostPrice * (1 + ISNULL(c.RSPPercentage, 0) / 100), 2, 1) AS NUMERIC(18, 2)) AS CorrectRetailerPrice
		,p.WholesalerPrice
		,CAST(ROUND(p.CostPrice * (1 + ISNULL(c.WSPPercentage, 0) / 100), 2, 1) AS NUMERIC(18, 2)) AS CorrectWholesalerPrice
	FROM Products p WITH (NOLOCK)
	INNER JOIN Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
		AND c.IsDeleted = 0
		AND c.IsSellByPerSQFT = 1
		AND c.TenantId = p.TenantId
		and p.IsPriceAutoCalculated=1
	INNER JOIN ProductCustomFields pcf WITH (NOLOCK) ON pcf.ProductId = p.ProductId
		AND pcf.IsDeleted = 0
		AND pcf.TenantId = p.TenantId
	INNER JOIN LookupValues lv WITH (NOLOCK) ON lv.LookupValueId = pcf.LookupValueId
		AND lv.IsDeleted = 0
		AND lv.LookupValueName = 'SQFT in BOX'
	WHERE p.Status <> 3
)
SELECT *
	--,'UPDATE p SET p.RetailerPrice = 171.47, p.WholesalerPrice = 171.47 FROM Products p WHERE p.ProductId = 106342' AS UpdateStatement
	,'EXEC UpdateProductPriceByCategory @TenantId = '+CAST(TenantId AS VARCHAR(10))+', @CategoryId = '+CAST(CategoryId AS VARCHAR(10))+', @ProductId = '+CAST(ProductId AS VARCHAR(10))+'' AS UpdatePriceExecuteSP
FROM SQFTProducts
WHERE (
		RetailerPrice <> CorrectRetailerPrice
		OR WholesalerPrice <> CorrectWholesalerPrice
	)
AND (
		(RetailerPrice - CorrectRetailerPrice) > 1
		OR (WholesalerPrice - CorrectWholesalerPrice) > 1
	)

GO

