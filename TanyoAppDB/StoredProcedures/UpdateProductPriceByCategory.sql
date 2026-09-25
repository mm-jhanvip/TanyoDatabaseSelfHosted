/* 
	EXEC [dbo].[UpdateProductPriceByCategory]
		@TenantID = 1
		,@CategoryID = 1
		,@ProductID = 0
*/
CREATE PROC [dbo].[UpdateProductPriceByCategory] (
	@TenantID BIGINT
	,@CategoryID BIGINT
	,@ProductID BIGINT = 0
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;;

	BEGIN TRY
		WITH cte
		AS (
			SELECT p.ProductId
				,CAST(ROUND(p.CostPrice * (1 + ISNULL(c.RSPPercentage, 0) / 100), 2, 1) AS NUMERIC(18, 2)) AS RetailerPrice
				,CAST(ROUND(p.CostPrice * (1 + ISNULL(c.WSPPercentage, 0) / 100), 2, 1) AS NUMERIC(18, 2)) AS WholesalerPrice
				,t.AmountRoundMultiple
			FROM dbo.Products p WITH (NOLOCK)
			INNER JOIN dbo.Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
				AND c.TenantId = p.TenantId
			INNER JOIN dbo.Tenants t WITH (NOLOCK) ON t.TenantId = p.TenantId
			WHERE t.TenantId = @TenantID
				AND c.CategoryID = @CategoryID
				AND (
					@ProductID = 0
					OR p.ProductId = @ProductID
					)
				AND p.IsPriceAutoCalculated = 1
			)
			,cte2
		AS (
			SELECT c.ProductId
				,CASE 
					WHEN c.AmountRoundMultiple > 0
						AND c.RetailerPrice > 0
						THEN CAST(ROUND((c.RetailerPrice) / c.AmountRoundMultiple, 0) * c.AmountRoundMultiple AS NUMERIC(18, 2))
					ELSE c.RetailerPrice
					END AS RetailerPrice
				,CASE 
					WHEN c.AmountRoundMultiple > 0
						AND c.WholesalerPrice > 0
						THEN CAST(ROUND((c.WholesalerPrice) / c.AmountRoundMultiple, 0) * c.AmountRoundMultiple AS NUMERIC(18, 2))
					ELSE c.WholesalerPrice
					END AS WholesalerPrice
			FROM cte c
			)
		UPDATE p
		SET p.RetailerPrice = c.RetailerPrice
			,p.WholesalerPrice = c.WholesalerPrice
		FROM Products p
		INNER JOIN cte2 c ON c.ProductId = p.ProductId
		WHERE p.TenantId = @TenantID
			AND p.CategoryId = @CategoryID
			AND (
				@ProductID = 0
				OR p.ProductId = @ProductID
				)
			AND p.IsPriceAutoCalculated = 1

		DECLARE @Result INT

		IF @ProductID > 0
		BEGIN
			DECLARE @ProductIds VARCHAR(MAX) = CAST(@ProductID AS VARCHAR(MAX))

			EXEC [dbo].[UpdateProductOfferPrice] @TenantId = @TenantID
				,@CategoryId = @CategoryID
				,@ProductIds = @ProductIds
				,@Result = @Result OUTPUT
		END
		ELSE
		BEGIN
			EXEC [dbo].[UpdateProductOfferPrice] @TenantId = @TenantID
				,@CategoryId = @CategoryID
				,@Result = @Result OUTPUT
		END

		--UPDATE PT
		--SET PT.RetailOfferPrice = PT.RetailerPrice - ((PT.RetailerPrice * opm.OfferPercentage) / 100)
		--	,PT.WholesalerOfferPrice = PT.WholesalerPrice - ((PT.WholesalerPrice * opm.OfferPercentage) / 100)  
		--FROM Products PT
		--INNER JOIN Categories CT ON PT.CategoryId = CT.CategoryId
		--INNER JOIN ProductOffers OPM ON OPM.ProductId = PT.ProductId
		--	AND CT.TenantId = @TenantID
		--	and pt.CategoryID = @CategoryID
		--	AND (
		--		@ProductID = 0
		--		OR pt.ProductId = @ProductID
		--		)
		--	AND (
		--		PT.RetailOfferPrice <> (PT.RetailerPrice - ((PT.RetailerPrice * opm.OfferPercentage) / 100))
		--		OR PT.WholesalerOfferPrice <> (PT.WholesalerPrice - ((PT.WholesalerPrice * opm.OfferPercentage) / 100)) 
		--		)
		SELECT CAST(1 AS BIT) AS [Status]
			,'Success' AS [Message]
			,JSON_QUERY('{"TenantID": ' + CAST(@TenantID AS VARCHAR(MAX)) + ', "CategoryID": ' + CAST(@CategoryID AS VARCHAR(MAX)) + '}') AS [Data]
			,NULL AS [Error]
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

