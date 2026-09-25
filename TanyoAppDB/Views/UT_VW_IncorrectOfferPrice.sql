


CREATE ViEW [dbo].[UT_VW_IncorrectOfferPrice]
WITH ENCRYPTION
AS
SELECT p.ProductId
	,p.ProductTitle
	,[dbo].[CalculateTotalOfferAmount](p.RetailerPrice,o.OfferPercentage) AS RetailOfferPriceFromFunction
	,p.RetailOfferPrice
	--,[dbo].[CalculateTotalOfferAmount](p.WholesalerPrice,o.OfferPercentage) AS WholesalerOfferPriceFromFunction
	--,p.WholesalerOfferPrice
	FROM Products p
	INNER JOIN OfferProductMapping opm ON opm.ProductId = p.ProductId
	INNER JOIN Offers o ON o.OfferId = opm.OfferId
	WHERE o.StartDate <= GETDATE()
		AND o.EndDate >= GETDATE()
		AND o.IsPublished = 1
		AND 
			abs(ISNULL(p.RetailOfferPrice,0) - [dbo].[CalculateTotalOfferAmount](p.RetailerPrice,o.OfferPercentage))>1
			--OR 
			--ISNULL(p.WholesalerOfferPrice,0) <> [dbo].[CalculateTotalOfferAmount](p.WholesalerPrice,o.OfferPercentage)

GO

