CREATE PROCEDURE GetOrderShippingAddressDetails (@OrderId BIGINT)
WITH ENCRYPTION
AS
BEGIN
	SELECT OA.OrderAddressId
	    ,OA.OrderId
		,OA.CustomerAddressId
		,OA.Street1
		,ISNULL(OA.Street2, '') AS Street2
		,ISNULL(OA.Landmark, '') AS Landmark
		,OA.Area
		,OA.City
		,OA.State
		,OA.ZipCode
		,OA.Latitude
		,OA.Longitude
	FROM OrderAddresses OA WITH (NOLOCK)
	WHERE OA.OrderId = @OrderId
		AND OA.AddressType = 'Shipping'
END

GO

