
/*
	Author		: Harsh P
	Created Date: 2025-04-15
	Description	: It will return the Product detail with offer details too
	EXEC STMT	: SELECT * FROM Vw_ListProductsWithOffer
*/
CREATE VIEW [dbo].[Vw_ListProductsWithOffer]
WITH ENCRYPTION
AS
	SELECT t.CategoryName
	,p.ProductId
	,p.ProductTitle
	,p.ModelNo
	,p.Features
	,p.Height
	,p.Width
	,p.Depth
	,pq.Quantity AS StockQuantity
	,p.RetailerPrice AS [RetailerPrice]
	,CASE 
		WHEN ofr.OfferId IS NOT NULL 
				THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
	END AS IsOfferAvailable
	,ofr.OfferPercentage
	,CASE 
		WHEN ofr.OfferId IS NOT NULL
			THEN 
				p.RetailOfferPrice
			ELSE 0
			END [OfferPrice]
		,p.TenantId
		,p.Status
	FROM dbo.Products AS p WITH (NOLOCK)
	INNER JOIN dbo.ProductQuantities AS pq WITH (NOLOCK) ON p.ProductId = pq.ProductId
	INNER JOIN dbo.Categories AS t WITH (NOLOCK) ON p.CategoryId = t.CategoryId
	INNER JOIN dbo.AspNetUsers AS [as] WITH (NOLOCK) ON p.CreatedBy = [as].UserId
	LEFT JOIN ProductOffers ofr ON ofr.ProductId = p.ProductId
	LEFT JOIN (
		SELECT pvm.ProductId,
				STRING_AGG(v.VendorName, ', ') AS VendorName
		FROM dbo.ProductVendorMapping AS pvm
		INNER JOIN dbo.Vendors AS v ON pvm.VendorId = v.VendorId
		GROUP BY pvm.ProductId
	) AS pv ON p.ProductId = pv.ProductId
	WHERE p.STATUS <> 3

GO

