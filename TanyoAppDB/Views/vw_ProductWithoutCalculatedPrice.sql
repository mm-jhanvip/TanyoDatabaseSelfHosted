--SELECT * FROM vw_ProductWithoutCalculatedPrice
CREATE VIEW vw_ProductWithoutCalculatedPrice
WITH ENCRYPTION
AS
	SELECT DISTINCT p.TenantId, p.CategoryId
		,'EXEC [dbo].[UpdateProductPriceByCategory] @TenantID = '+CAST(p.TenantId AS VARCHAR)+', @CategoryID = '+CAST(p.CategoryId AS VARCHAR)+'' AS Query
	FROM Products p WITH (NOLOCK)
	INNER JOIN Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
		AND c.IsDeleted = 0
	WHERE p.CostPrice <> 0.00
	AND (p.RetailerPrice = 0.00 OR p.WholesalerPrice = 0.00)
	AND p.Status <> 3

GO

