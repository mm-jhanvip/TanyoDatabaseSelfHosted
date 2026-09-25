
--SELECT * FROM [dbo].[OrderAddress_View] WHERE TenantId = 1 ORDER BY 2
CREATE VIEW [dbo].[OrderAddress_View]
WITH ENCRYPTION
AS
SELECT o.TenantId
	,o.OrderId
    ,o.Status
    ,o.OrderNo
	,o.TotalAmt
	,CAST(ISNULL(o.ApprovedDate, o.CreatedDate) AS DATE) AS OrderDate
    ,os.AddressType 
    ,os.Street1
    ,os.Street2
    ,os.Landmark
    ,os.Area
    ,os.City
    ,os.State
    ,os.ZipCode
	,os.Latitude
	,os.Longitude
FROM Orders o WITH (NOLOCK)
LEFT JOIN OrderAddresses os WITH (NOLOCK) ON o.OrderId = os.OrderId
	AND os.AddressType = 'Shipping'
WHERE o.Status NOT IN (6, 9)

GO

