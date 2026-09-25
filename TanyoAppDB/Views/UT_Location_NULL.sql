--select * from [UT_Location_NULL]
CREATE VIEW [dbo].[UT_Location_NULL]
WITH ENCRYPTION
AS
	SELECT 'Leads' AS TableName, COUNT(1) AS TotalCount
	FROM Leads l1 WITH (NOLOCK)
	INNER JOIN Locations l ON l.TenantID = l1.TenantId
	WHERE l.LocationName = 'Main'
	AND l1.LocationID IS NULL
	having COUNT(1)>0

	UNION

	SELECT 'Customers', COUNT(1) AS TotalCount
	FROM Customers l1 WITH (NOLOCK)
	INNER JOIN Locations l ON l.TenantID = l1.TenantId
	WHERE l.LocationName = 'Main'
	AND l1.LocationID IS NULL
	AND l1.IsDeleted = 0
	having COUNT(1)>0
	
	UNION

	SELECT 'Orders', COUNT(1) AS TotalCount
	FROM Orders l1 WITH (NOLOCK)
	INNER JOIN Locations l ON l.TenantID = l1.TenantId
	WHERE l.LocationName = 'Main'
	AND l1.LocationID IS NULL
	AND l1.Status <> 9
	having COUNT(1)>0
	
	UNION

	SELECT 'TenantBankDetails', COUNT(1) AS TotalCount
	FROM TenantBankDetails l1 WITH (NOLOCK)
	INNER JOIN Locations l ON l.TenantID = l1.TenantId
	WHERE l.LocationName = 'Main'
	AND l1.LocationID IS NULL
	AND l1.IsDeleted = 0
	having COUNT(1)>0

GO

