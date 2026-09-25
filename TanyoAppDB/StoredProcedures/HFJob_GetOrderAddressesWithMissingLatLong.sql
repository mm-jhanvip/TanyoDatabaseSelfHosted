CREATE PROCEDURE [dbo].[HFJob_GetOrderAddressesWithMissingLatLong]
WITH ENCRYPTION
AS
BEGIN
	SELECT OA.CustomerAddressId
		,OA.City
		,OA.STATE
		,OA.ZipCode
		,OA.OrderAddressId
	FROM OrderAddresses OA WITH (NOLOCK)
	WHERE ISNULL(OA.ZipCode, '') <> ''
		AND (
				OA.Latitude IS NULL
			OR OA.Longitude IS NULL
			)
END

GO

