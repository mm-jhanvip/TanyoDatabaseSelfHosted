--SELECT * FROM vw_ReadyToDeliveredItems
CREATE   VIEW [dbo].[vw_ReadyToDeliveredItems]
WITH ENCRYPTION
AS
	SELECT o.OrderId
		,o.TenantId
		,os.SubjectId
		,os.SubjectTypeId
		,os.Quantity
		,O.Status
	FROM dbo.Orders o WITH (NOLOCK)
	INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
	WHERE os.IsDeleted = 0
	AND o.Status IN (2,3)
	AND os.ItemStatus IN (0,1,2)
	--AND o.Status IN (3,4,5,6,7)

GO

