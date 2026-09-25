
--select * from [UT_Missing_RetailerPrice] order by tenantid
CREATE VIEW [dbo].[UT_Missing_RetailerPrice]
WITH ENCRYPTION
AS
SELECT 
		t.TenantId
		,t.TenantName 
		,P.ProductId AS 'ProductId'
			,p.CoverImage AS 'CoverImage'
			,P.ProductTitle AS 'ProductTitle'
			,P.ModelNo AS 'ModelNo'
			,cat.CategoryName AS 'CategoryName'
			,p.RetailerPrice
		FROM Products AS p WITH (NOLOCK)
		INNER JOIN Categories AS cat WITH (NOLOCK) ON p.CategoryId = cat.CategoryId
		INNER JOIN Tenants t ON t.TenantId = p.TenantId
		WHERE cat.IsDeleted = 0
			AND (
				p.RetailerPrice = 0
				OR p.RetailerPrice IS NULL
				)
			AND P.STATUS != 3
			and p.TenantId NOT IN(185, 193) --Novelty and Zula n more
		--ORDER BY t.TenantName, p.ProductTitle

GO

