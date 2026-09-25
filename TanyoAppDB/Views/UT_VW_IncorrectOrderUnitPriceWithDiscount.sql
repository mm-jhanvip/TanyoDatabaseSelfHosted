
--SELECT * FROM dbo.UT_VW_IncorrectOrderUnitPriceWithDiscount
CREATE VIEW [dbo].[UT_VW_IncorrectOrderUnitPriceWithDiscount]
WITH ENCRYPTION
AS
SELECT t.TenantId
	,t.TenantName
	,o.OrderNo
	,o.Status
	,osi.OrderSetItemId
	,osi.InstantUnitPrice
	,osi.UnitPrice
	,osi.DiscountPrice
	,osi.Discount
	,osi.UnitSalePrice
	,osi.Quantity
	,osi.GrossTotal
	,osi.AmountBeforeGST
	,osi.SGSTAmount
	,osi.CGSTAmount
	,osi.TotalAmount
	,'EXEC UpdateOrderRefreshInquiry @OrderId = '+CAST(o.OrderId AS VARCHAR(MAX))+', @TenantId = '+CAST(o.TenantId AS VARCHAR(MAX))+', @UserId = '+CAST(ISNULL(o.UpdatedBy, o.CreatedBy) AS VARCHAR(MAX))+'' AS ToFix
FROM Orders o WITH (NOLOCK)
INNER JOIN OrderSetItems osi WITH (NOLOCK) ON osi.OrderId = o.OrderId
	AND osi.IsDeleted = 0
INNER JOIN Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
INNER JOIN Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
	AND c.CategoryTypeId = 2
INNER JOIN Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
	AND t.IsDeleted = 0
	AND t.IsDemo = 0
WHERE o.Status <> 9
AND osi.InstantUnitPrice <> osi.UnitPrice
AND osi.InstantUnitPrice > 0
AND osi.DiscountPrice > 0
AND osi.OfferId IS NULL

GO

