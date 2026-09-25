
CREATE VIEW [dbo].[UT_Incorrect_OrderUsers]
WITH ENCRYPTION
AS
SELECT o.OrderID, 
		o.OrderNo,
		o.TenantId,
		t.TenantName,
		o.UpdatedBy
FROM Orders o
INNER JOIN UserTenantmapping utm ON utm.UserId = o.updatedBy
INNER JOIN tenants t ON t.TenantId = o.TenantId
--INNER JOIN vw_TanyoUsers u ON u.UserId = utm.UserId
WHERE o.tenantId <> utm.tenantId

GO

