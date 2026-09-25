CREATE VIEW [dbo].[UT_VW_OrphanOrderSetItem]
WITH ENCRYPTION
AS
SELECT osi.*
FROM OrderSetItems osi WITH (NOLOCK)
LEFT JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
WHERE o.OrderId IS NULL

GO

