Create VIEW  [vw_OrderSummary]
WITH ENCRYPTION
AS
SELECT T.TenantName
,CONCAT(CS.FirstName,' ' ,ISNULL(CS.LastName,'')) AS Customername
,ORD.OrderNo
,CAst(ORD.CreatedDate AS datetime) AS OrderDate
,PT.ProductTitle
,PT.ModelNo
,ORD.AmountBeforeGST + (ORD.CGSTAmount *2) + ISNULL(ORD.SpecialDiscount,0) AS OrderAmount
,OSI.Quantity,osi.UnitPrice
,OSI.AmountBeforeGST + (OSI.CGSTAmount *2) AS TotalAmountByProduct 
,CONCAT(OA.Street1, ' ' , ISNULL(OA.Street2,''),' ' ,OA.Area,' ' ,OA.City,' ' ,OA.State,' ' ,OA.ZipCode) AS CustomerShippingAddress 
,ORD.Comments AS OrderComments
FROM OrderSetItems OSI WITH (NOLOCK)
INNER JOIN Orders ORD WITH (NOLOCK) ON ORD.OrderId = OSI.OrderId
INNER JOIN Products PT WITH (NOLOCK) ON PT.ProductId = OSI.SubjectId AND PT.TenantId = ORD.TenantId
INNER JOIN Tenants T  WITH (NOLOCK) ON T.TenantId = ORD.TenantId  
INNER JOIN Customers CS WITH (NOLOCK) ON CS.CustomerId = ORD.CustomerID
INNER JOIN OrderAddresses OA WITH (NOLOCK) ON OA.OrderId = ORD.OrderId AND OA.AddressType = 'Shipping'
WHERE OSI.IsDeleted = 0
	AND t.Isdeleted = 0

GO

