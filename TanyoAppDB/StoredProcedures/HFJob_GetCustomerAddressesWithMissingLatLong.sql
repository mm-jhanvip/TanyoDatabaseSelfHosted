CREATE   PROCEDURE HFJob_GetCustomerAddressesWithMissingLatLong
WITH ENCRYPTION
AS
BEGIN
	SELECT CA.CustomerAddressId
		,CA.City
		,CA.STATE
		,CA.ZipCode
	FROM CustomerAddresses CA WITH (NOLOCK)
	WHERE CA.IsDeleted = 0
		AND ISNULL(CA.ZipCode, '') <> ''
		AND (
				CA.Latitude IS NULL
			OR CA.Longitude IS NULL
			)
END

GO

