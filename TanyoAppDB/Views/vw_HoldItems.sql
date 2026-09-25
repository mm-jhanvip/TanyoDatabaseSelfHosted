--SELECT * FROM vw_HoldItems
CREATE VIEW [dbo].[vw_HoldItems]
WITH ENCRYPTION
AS
	SELECT o.OrderId
		,o.TenantId
		,osi.SubjectId
		,osi.SubjectTypeId
		,soh.HoldUptoDate
		,soh.Quantity
	FROM OrderSetItems osi WITH (NOLOCK)
	INNER JOIN StockOnHold soh WITH (NOLOCK) ON soh.OrderSetItemId = osi.OrderSetItemId
	INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = soh.OrderId
	WHERE osi.IsDeleted = 0
	AND o.Status IN (0,1)
	AND soh.ProductId = osi.SubjectId
	AND soh.IsStockOnHold = 1
	AND osi.IsQuantityOnHold = 1

GO

