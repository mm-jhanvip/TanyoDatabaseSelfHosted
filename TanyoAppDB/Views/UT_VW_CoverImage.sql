

--select * from [UT_VW_CoverImage] ORDER BY 1
CREATE VIEW [dbo].[UT_VW_CoverImage]
WITH ENCRYPTION
AS
SELECT t.TenantName, p.ProductId
	,p.ProductTitle
	,p.ModelNo
	,p.CreatedDate
	,p.Status
	,u.FirstName + ' ' + u.LastName As CreatedBy
	,CoverImage
	,x.ImagePath
	FROM Products p 
	INNER JOIN Tenants t on t.TenantId = p.TenantId
		AND p.Status <> 3 --Deleted
	LEFT JOIN aspnetusers u on u.UserID = p.CreatedBy
	INNER JOIN (
		SELECT x.ProductId
			,x.ImagePath
		FROM (
			SELECT im.ProductId
				,im.ImagePath
				,ROW_NUMBER() OVER (
					PARTITION BY im.ProductId ORDER BY im.IsCover DESC
						,im.CreatedUTCDate DESC, im.ProductImageID DESC
					) AS RowID
			FROM ProductImages im WITH (NOLOCK)
			INNER JOIN Products tp ON tp.ProductId = im.Productid
			) x
		WHERE x.RowID = 1
		) x ON x.ProductId = p.ProductId
	WHERE ISNULL(p.CoverImage, '') <> x.ImagePath

GO

