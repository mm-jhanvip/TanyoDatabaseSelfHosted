


--SELECT * FROM UT_VW_OrderUnitPriceIncorrect where tenantid=156
CREATE VIEW [dbo].[UT_VW_OrderUnitPriceIncorrect]
WITH ENCRYPTION
AS
SELECT t.TenantId
	,t.TenantName
	,'EXEC dbo.UpdateOrderRefreshInquiry @OrderId = '+CAST(o.OrderId AS VARCHAR)+',@TenantId = '+CAST(o.TenantId AS VARCHAR)+',@UserId = '+CAST(o.CreatedBy AS VARCHAR)+'' AS ToFix
	,o.OrderNo
	,o.[Status]
	,osi.*
FROM OrderSetItems osi WITH (NOLOCK)
INNER JOIN Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
INNER JOIN Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
	AND t.IsDeleted = 0
	AND t.IsDemo = 0
	--and t.TenantId <> 156 --RichVibe allowed to have UnitPrice 0
WHERE osi.UnitPrice = 0
AND osi.IsDeleted = 0
AND osi.Quantity > 0
AND o.Status NOT IN (5,8,9)
AND p.CostPrice > 0
and o.OrderNo NOT IN('W17008-27122025')

GO

