CREATE VIEW Cust_Visited_not_Ordered
WITH ENCRYPTION
AS
SELECT c.CustomerId,
    c.FirstName,
    c.LastName,
    c.EmailId,
    c.PhoneNumber,
	cv.CreatedDate AS VisitedDate,
	DATEDIFF(DAY,cv.CreatedDate,GETDATE()) AS Spent_Days
FROM Customers c
INNER JOIN (
			SELECT MAX(CreatedDate) AS CreatedDate
					,CustomerID 
			FROM CustomerVisits
			GROUP BY CustomerID 
			) cv ON cv.CustomerID = c.CustomerId
LEFT JOIN Orders O  ON o.CustomerID = cv.CustomerId
	AND o.CreatedDate > cv.CreatedDate
WHERE o.CustomerID IS NULL

GO

