CREATE VIEW [dbo].[UT_VW_DeletedProductsInQuotations]
WITH ENCRYPTION
AS
SELECT t.TenantId
	,t.TenantName
	,o.OrderNo
	,osi.*
FROM OrderSetItems osi WITH (NOLOCK)
LEFT JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
LEFT JOIN Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
LEFT JOIN Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
WHERE p.ProductId IS NULL

GO

