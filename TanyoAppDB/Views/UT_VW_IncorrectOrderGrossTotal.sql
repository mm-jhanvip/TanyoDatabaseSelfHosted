

--SELECT * FROM UT_VW_IncorrectOrderGrossTotal
CREATE VIEW [dbo].[UT_VW_IncorrectOrderGrossTotal]
WITH ENCRYPTION
AS
SELECT o.TenantId
	,t.TenantName
	,o.OrderId
	,o.OrderNo
	,'EXEC dbo.UpdateOrderRefreshInquiry @OrderId = '+CAST(o.OrderId AS VARCHAR(100))+',@TenantId = '+CAST(o.TenantId AS VARCHAR(100))+',@UserId = '+CAST(o.CreatedBy AS VARCHAR(100))+'' As ToFix
	,x.OrderGrossTotal
	,x.OrderSetItemGrossTotal
	,x.OrderGrossTotal - x.OrderSetItemGrossTotal AS Diff
FROM (
SELECT o.OrderId
	,o.OrderNo
	,MIN(o.GrossTotal) AS OrderGrossTotal
	,SUM(osi.GrossTotal) AS OrderSetItemGrossTotal
FROM Orders o WITH (NOLOCK)
INNER JOIN OrderSetItems osi WITH (NOLOCK) ON osi.OrderId = o.OrderId
	AND osi.IsDeleted = 0
GROUP BY o.OrderId
	,o.OrderNo
) x
INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = x.OrderId
INNER JOIN tenants t on t.TenantId = o.TenantId
WHERE (x.OrderGrossTotal - x.OrderSetItemGrossTotal) > 0
OR (x.OrderGrossTotal - x.OrderSetItemGrossTotal) < 0

GO

