CREATE VIEW [dbo].[CombinedSalesAnalysis]
WITH ENCRYPTION
AS
WITH cte AS (
	SELECT
    	osi.CreatedDate AS dt,
    	p.ProductID,
    	CAST(osi.CreatedDate AS DATE) AS Date,
    	p.ProductTitle AS Product,
    	'Sales' AS Type,
    	NULL AS CostPrice,
    	osi.Quantity,
    	osi.UnitPrice * (CASE WHEN osi.DiscountPrice > 0 THEN (osi.DiscountPrice / 100) ELSE 1 END) AS SalesPrice,
    	p.TenantId,
    	NULL AS SalesmanName,
    	NULL AS CustomerName,
    	NULL AS Status
	FROM OrderSetItems osi WITH(NOLOCK)
	INNER JOIN SubjectTypes st WITH(NOLOCK) ON st.SubjectTypeId = osi.SubjectTypeId
	INNER JOIN Products p WITH(NOLOCK) ON p.ProductId = osi.SubjectId
	WHERE st.SubjectTypeName = 'Products'
    
	UNION ALL
    
	SELECT
    	ide.CreatedDate AS dt,
    	p.ProductID,
    	CAST(ide.CreatedDate AS DATE) AS Date,
    	p.ProductTitle AS Product,
    	'Inward' AS Type,
    	ide.Amount AS CostPrice,
    	ide.Quantity,
    	NULL AS SalesPrice,
    	p.TenantId,
    	NULL AS SalesmanName,
    	NULL AS CustomerName,
    	NULL AS Status
	FROM InwardDetailsEntry ide WITH(NOLOCK)
	INNER JOIN Products p WITH(NOLOCK) ON p.ProductId = ide.ProductId
)

SELECT
	cte.ProductID,
	cte.Date,
	cte.Product,
	cte.Type,
	cte.CostPrice,
	cte.Quantity,
	cte.SalesPrice,
	cte.TenantId,
	sa.TenantName,
	sa.SalesmanName,
	sa.CustomerName,
	sa.Status
FROM cte
LEFT JOIN (
	SELECT
    	CAST(o.CreatedDate AS DATE) AS Date,
    	o.TenantId,
    	t.TenantName,
    	au.FirstName + ' ' + au.LastName AS SalesmanName,
    	ISNULL(c1.LastName, '') + c1.FirstName AS CustomerName,
    	p.ProductTitle AS ProductName,
    	osi.Quantity,
    	osi.UnitPrice,
    	CASE WHEN o.Status = 0 THEN 'Pending' ELSE 'Confirmed' END AS Status  
	FROM Orders o WITH(NOLOCK)
	INNER JOIN OrderSetItems osi WITH(NOLOCK) ON osi.OrderId = o.OrderId
	INNER JOIN SubjectTypes st WITH(NOLOCK) ON st.SubjectTypeId = osi.SubjectTypeId
	INNER JOIN Products p WITH(NOLOCK) ON p.ProductId = osi.SubjectId
	INNER JOIN Customers c1 WITH(NOLOCK) ON c1.CustomerId = o.CustomerID
	INNER JOIN AspNetUsers au WITH(NOLOCK) ON au.UserId = o.SalesmanId
	INNER JOIN Tenants t WITH(NOLOCK) ON t.TenantId = o.TenantId
	WHERE
    	st.SubjectTypeName = 'Products'
    	AND o.Status NOT IN (6,8,9)
) sa
ON cte.Date = sa.Date AND cte.TenantId = sa.TenantId AND cte.Product = sa.ProductName

GO

