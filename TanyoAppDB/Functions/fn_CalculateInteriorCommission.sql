CREATE     FUNCTION [dbo].[fn_CalculateInteriorCommission] 
(	
	@OrderID BIGINT
)
RETURNS TABLE 
WITH ENCRYPTION
AS
RETURN 
(
	SELECT os.OrderSetItemId,
		(CASE WHEN t.IsBeforeGST = 1 THEN os.AmountBeforeGST ELSE os.TotalAmount END) * ISNULL(o.InteriorCommissionPer,0)/100 As InteriorCommission
	FROM OrderSetItems os
	INNER JOIN Orders o ON o.OrderId = os.OrderId
	INNER JOIN SubjectTypes st ON st.SubjectTypeId=os.SubjectTypeId
	INNER JOIN Products p on p.ProductId=os.SubjectId
	INNER JOIN Categories c on c.CategoryId=p.CategoryId
	INNER JOIN Tenants t ON t.TenantId = o.TenantId
	WHERE o.OrderID = @OrderID
	AND c.IsCommissionEnabledInterior=1
	AND st.SubjectTypeName='Products'
)

GO

