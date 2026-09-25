/*
	Author		: Harsh P
	Created Date: 2025-04-15
	Description	: It will return the customer related data for the chat bot
	EXEC STMT	: SELECT * FROM Vw_CustomerDetail
*/
CREATE VIEW Vw_CustomerDetail
WITH ENCRYPTION
AS
	With Cte as
	(
	SELECT ISNULL(c.FirstName,'')+ISNULL(LastName,'') AS CustomerName
		,CA.Street1 
		,CA.Street2 
		,CA.Landmark 
		,CA.Area 
		,CA.City 
		,CA.STATE
		,CA.ZipCode
		,c.TenantId
		,ROW_NUMBER() OVER (PARTITION BY CA.CustomerId ORDER BY CA.CustomerAddressId DESC) AS Row_Id
	FROM Customers c
	INNER JOIN CustomerAddresses CA ON CA.CustomerId = c.CustomerId	
	)
	SELECT CustomerName
		,Street1
		,Street2
		,Landmark
		,Area
		,City
		,State
		,ZipCode
		,TenantId
	FROM Cte
	WHERE Row_Id = 1

GO

