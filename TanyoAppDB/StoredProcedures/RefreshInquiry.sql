CREATE PROCEDURE [dbo].[RefreshInquiry]
(
	@RefreshInquiry BIT
	,@OrderID BIGINT
	,@ProductSubjectTypeId BIGINT
	,@FabricSubjectTypeId BIGINT
	,@PolishSubjectTypeId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	
	SET NOCOUNT ON;

	--Add Product Image in OrderSetItem
	UPDATE osi
	SET osi.GST = IIF(osi.ParentOrderSetItemId IS NULL, c.GST, 18)
	,osi.ProductImage = p.CoverImage
	FROM dbo.OrderSetItems osi
	INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
	INNER JOIN dbo.Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
	--LEFT JOIN dbo.ProductImages pii WITH (NOLOCK) ON pii.ProductId = osi.SubjectId
	--	AND pii.IsCover = 1
	WHERE osi.SubjectTypeId = @ProductSubjectTypeId
	AND osi.IsDeleted = 0
	AND osi.OrderId = @OrderID
 
	--Add Fabric Image in OrderSetItem
	UPDATE osi
	SET osi.GST = IIF(osi.ParentOrderSetItemId IS NULL, f.GST, 18)
		,osi.ProductImage = f.ImagePath
	FROM dbo.OrderSetItems osi
	INNER JOIN dbo.Fabrics f WITH (NOLOCK) ON f.FabricId = osi.SubjectId
	WHERE osi.SubjectTypeId = @FabricSubjectTypeId
	AND osi.IsDeleted = 0
	AND osi.OrderId = @OrderID
 
	--Add Polish Image in OrderSetItem
	UPDATE osi
	SET osi.GST = IIF(osi.ParentOrderSetItemId IS NULL, p.GST, 18)
		,osi.ProductImage = p.ImagePath
	FROM dbo.OrderSetItems osi
	INNER JOIN dbo.Polish p WITH (NOLOCK) ON p.PolishId = osi.SubjectId
	WHERE osi.SubjectTypeId = @PolishSubjectTypeId
	AND osi.IsDeleted = 0
	AND osi.OrderId = @OrderID
	
END

GO

