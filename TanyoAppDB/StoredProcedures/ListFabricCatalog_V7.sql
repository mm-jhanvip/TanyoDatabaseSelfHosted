/*  
	EXEC [dbo].[ListFabricCatalog_V7]  
	   @TenantId = 2
	  ,@RoleId = '555D131D-3306-40AC-9A7B-6CBDA78A1C2F'
*/
CREATE   PROCEDURE [dbo].[ListFabricCatalog_V7] (
	@TenantId INT
	,@RoleId NVARCHAR(MAX)
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM AspNetRoleClaims arc
				INNER JOIN AspNetRoles ar ON ar.Id = arc.RoleId
					AND ar.TenantId = @TenantId
					AND ar.Id = @RoleId
				)
		BEGIN
			RAISERROR (
					'User does not belongs to tenant'
					,15
					,1
					)

			RETURN
		END

		DECLARE @dt DATE

		SELECT @dt = CAST(GETDATE() AS DATE)

		DECLARE @ProductSubjectTypeId INT

		SELECT @ProductSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
			AND st.SubjectTypeName = 'Products'

		DECLARE @HasWholesalerPrice BIT = 0;

		SELECT @HasWholesalerPrice = CASE 
				WHEN EXISTS (
						SELECT 1
						FROM AspNetRoleClaims arc
						INNER JOIN AspNetRoles ar ON ar.Id = arc.RoleId
							AND ar.TenantId = @TenantId
							AND ar.Id = @RoleId
							AND arc.ClaimValue = 'Permissions.App.Order.WholeselerPrice'
						)
					THEN 1
				ELSE 0
				END

		SELECT p.ProductId AS ProductId
			,p.ProductTitle AS ProductTitle
			,p.ModelNo AS ModelNo
			,c.CategoryId AS CategoryId
			,c.CategoryName AS CategoryName
			,RIGHT(LEFT(p.CoverImage, CASE 
						WHEN CHARINDEX('?', p.CoverImage) > 0
							THEN CHARINDEX('?', p.CoverImage) - 1
						ELSE LEN(p.CoverImage)
						END), CHARINDEX('/', REVERSE(LEFT(p.CoverImage, CASE 
								WHEN CHARINDEX('?', p.CoverImage) > 0
									THEN CHARINDEX('?', p.CoverImage) - 1
								ELSE LEN(p.CoverImage)
								END))) - 1) AS ProductImage
			,CASE 
				WHEN @HasWholesalerPrice = 0
					THEN p.RetailerPrice
				ELSE p.WholesalerPrice
				END AS OriginalPrice
			,ISNULL(CASE 
						WHEN @HasWholesalerPrice = 0
							THEN p.RetailerPrice
						ELSE p.WholesalerPrice
						END, 0) AS SalesPrice
			,p.Height AS Height
			,p.Width AS Width
			,p.Depth AS Depth
			,p.Diameter AS Diameter
			,p.Features AS [Description]
			,p.Features AS [Features]
			,p.FabricNeeded AS FabricNeeded
			,CAST(0 AS BIT) AS OfferTag
			,'' AS OfferCode
			,NULL AS OfferPercentage
			,NULL AS OfferTitle
			,CAST(0 AS BIGINT) AS OfferId
			--,'' AS ShareURL
			,@ProductSubjectTypeId AS SubjectTypeId
			,c.IsVisibleInAddOn AS IsPartOfAddOn
			,c.IsSellByPerSQFT AS IsSellByPerSQFT
			,'' AS ProductBrand
			,'' AS ProductColour
			,'' AS ProductMaterial
			,PQ.Quantity AS InStock
			,pii.ImageColorCode
		FROM dbo.Products p WITH (NOLOCK)
		INNER JOIN dbo.Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
			AND c.IsDeleted = 0
			AND c.TenantId = p.TenantId
			AND p.TenantId = @TenantId
			AND p.STATUS = 1
			AND c.CategoryTypeId = 2 -- 2 = Products, 2 = Fabrics
		INNER JOIN ProductQuantities PQ WITH (NOLOCK) ON PQ.ProductId = P.ProductId
		LEFT JOIN (
			SELECT TOP 1 pii.ImageColorCode
				,pii.ProductId
			FROM dbo.ProductImages pii WITH (NOLOCK)
			INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductId = pii.ProductId
				AND p.TenantId = @TenantId
				AND p.STATUS = 1
			INNER JOIN dbo.Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
				AND c.IsDeleted = 0
				AND c.TenantId = p.TenantId
				AND c.CategoryTypeId = 2 -- 1 = Products, 2 = Fabrics
			WHERE pii.IsCover = 1
			) pii ON pii.ProductId = p.ProductId
		WHERE   (
			(
				p.IsVisibleToWholesalers = 1 -- ON Wholesalers only
				AND @HasWholesalerPrice = 1
			)
		 OR p.IsVisibleToWholesalers = 0  
		)
	END
END;

GO

