

--SELECT * FROM UT_InvalidOrderDiscountAmount order by CreatedDate DESC
CREATE VIEW [dbo].[UT_InvalidOrderDiscountAmount]
WITH ENCRYPTION
AS
SELECT o.TenantId
	,t.TenantName
	,o.OrderId
	,o.OrderNo
	,o.CreatedDate
	,o.ApprovedDate
	,o.Status
	,osi.OrderSetItemID
	,osi.UnitPrice
	,osi.UnitSalePrice
	,osi.Quantity
	,osi.DiscountPrice
	,osi.Discount
	,osi.GrossTotal
	,osi.TotalAmount
	,CAST(ROUND(((osi.UnitPrice * osi.DiscountPrice) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0)) AS CorrectDiscount
	,osi.Discount AS CurrentDiscount
	,CAST(ROUND(((osi.UnitPrice * osi.DiscountPrice) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0)) - osi.Discount AS DiffDiscount
	,CAST(ROUND(((osi.UnitPrice * (100 - osi.DiscountPrice)) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0)) AS CorrectTotalAmount
	,osi.TotalAmount AS CurrentTotalAmount
	,CAST(ROUND(((osi.UnitPrice * (100 - osi.DiscountPrice)) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0)) - osi.TotalAmount AS DiffTotalAmount
--SELECT DISTINCT o.OrderId
--	,'EXEC UpdateRecalculateOrderAmountOnDelete @OrderId = ' + CAST(o.OrderId AS VARCHAR(100)) + ', @TenantId = ' + CAST(o.TenantId AS VARCHAR(100)) + ', @UserId = ' + CAST(o.UpdatedBy AS VARCHAR(100))
--	,'UPDATE osi SET osi.Discount = CAST(ROUND(((osi.UnitPrice * osi.DiscountPrice) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0)) FROM OrderSetItems osi WHERE OrderId = ' + CAST(o.OrderId AS VARCHAR(100))
FROM OrderSetItems osi WITH (NOLOCK)
INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
INNER JOIN Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
 --AND t.TenantId NOT IN (2,9,10,14,20,28,43,76,135,160)
 AND t.IsDeleted = 0
WHERE
(CAST(ROUND(((osi.UnitPrice * osi.DiscountPrice) / 100.0), 2) 
	* osi.Quantity AS NUMERIC(18, 0)) - osi.Discount) > 100
AND o.Status NOT IN (5,8,9)
and o.ApprovedDate > '2026-07-22'

GO

