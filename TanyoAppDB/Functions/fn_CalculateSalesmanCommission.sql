---------------------------------[dbo].[fn_CalculateSalesmanCommission]
	--SELECT * FROM dbo.fn_CalculateSalesmanCommision1 (53001)
	CREATE   FUNCTION [dbo].[fn_CalculateSalesmanCommission]
	(	
		@OrderID BIGINT
	)
	RETURNS TABLE 
WITH ENCRYPTION
AS
	RETURN 
	(
		SELECT os.OrderSetItemId,
			os.AmountBeforeGST * ISNULL(u.CommissionPer,0)/100 As SalesmanCommission
		FROM OrderSetItems os
		INNER JOIN Orders o ON o.OrderId = os.OrderId
		INNER JOIN AspNetUsers u ON u.UserId = o.SalesmanId
		INNER JOIN SubjectTypes st ON st.SubjectTypeId=os.SubjectTypeId
		INNER JOIN Products p on p.ProductId=os.SubjectId
		INNER JOIN Categories c on c.CategoryId=p.CategoryId
		WHERE o.OrderID = @OrderID
		AND c.IsCommissionEnabled=1
		AND st.SubjectTypeName='Products'
	)

GO

