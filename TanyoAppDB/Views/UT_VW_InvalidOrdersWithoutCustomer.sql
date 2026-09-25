

CREATE VIEW [dbo].[UT_VW_InvalidOrdersWithoutCustomer]
WITH ENCRYPTION
AS
SELECT *
from Orders o
where not exists(
	select 1
	from customers c
	where c.CustomerID = o.CustomerID
)

GO

