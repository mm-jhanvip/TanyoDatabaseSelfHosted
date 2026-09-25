



-- ==========================================================================
-- Author:      MagnusMinds
-- Create date: 24-11-2023
-- Description: Invalid orders and items
-- ==========================================================================
--select  * from [UT_InvalidOrderAndItemAmount] order by CreatedDate DESC
CREATE VIEW [dbo].[UT_InvalidOrderAndItemAmount]
WITH ENCRYPTION
AS
SELECT t.TenantName
	,o.OrderId
	,o.OrderNo
	,o.Status
	,o.CreatedDate
	,o.ApprovedDate
    ,MAX(o.TotalAmount)  AS [Total Order Amt]
    ,MAX(o.SpecialDiscount) AS SpecialDiscount
	,SUM(os.TotalAmount) AS [Total Items Amt]
	,MAX(o.TotalAmount) - SUM(os.TotalAmount) AS Diff
FROM dbo.Orders o WITH (NOLOCK)
INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
	AND os.IsDeleted = 0
INNER JOIN dbo.Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
WHERE o.Status <> 9
and o.ApprovedDate > '2026-07-22'
GROUP BY t.TenantName, o.OrderId, o.OrderNo, o.CreatedDate, o.Status, o.ApprovedDate
HAVING ABS((
		MAX(o.TotalAmount) 
		+ MAX(o.SpecialDiscount))  
		- SUM(os.TotalAmount)) > 10

GO

