
/*
	EXEC [dbo].[ListCatalogues] 
		@TenantId = 1207
		,@CatalogName = NULL
		,@PageIndex = 1
		,@PageSize = 332
		,@SortBy = 'CreatedDate'
		,@SortOrder = 'DESC'
*/
CREATE PROCEDURE [dbo].[ListCatalogues] (
	@TenantId INT
	,@CatalogName VARCHAR(250) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 10
	,@SortBy VARCHAR(50) = 'CreatedDate'
	,@SortOrder VARCHAR(50) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		;WITH PagedCatalogues
		AS (
			SELECT cat.CatalogueId
				,cat.CatalogueName
				,cat.CreatedDate
				,cat.CreatedUTCDate
				,cat.ProductPriceType
				,cat.CreatedBy
				,ISNULL(RTRIM(LTRIM(CONCAT (
								u.FirstName
								,' '
								,u.LastName
								))), '') AS CreatedName
				,COUNT(1) OVER () AS TotalCount
			FROM Catalogue cat WITH (NOLOCK)
			LEFT JOIN AspNetUsers u WITH (NOLOCK) ON cat.CreatedBy = u.UserId
			WHERE cat.TenantId = @TenantId
				AND cat.IsDeleted = 0
				AND (
					@CatalogName IS NULL
					OR @CatalogName = ''
					OR cat.CatalogueName LIKE '%' + @CatalogName + '%'
					)
			ORDER BY  
				CASE WHEN @SortOrder = 'ASC' AND @SortBy = 'CatalogueName' THEN cat.CatalogueName END ASC,
				CASE WHEN @SortOrder = 'DESC' AND @SortBy = 'CatalogueName' THEN cat.CatalogueName END DESC,
				CASE WHEN @SortOrder = 'ASC' AND @SortBy = 'ProductPriceType' THEN cat.ProductPriceType END ASC,
				CASE WHEN @SortOrder = 'DESC' AND @SortBy = 'ProductPriceType' THEN cat.ProductPriceType END DESC,
				CASE WHEN @SortOrder = 'ASC' AND @SortBy = 'CreatedName' THEN CONCAT(u.FirstName, ' ', u.LastName) END ASC,
				CASE WHEN @SortOrder = 'DESC' AND @SortBy = 'CreatedName' THEN CONCAT(u.FirstName, ' ', u.LastName) END DESC,
				CASE WHEN @SortOrder = 'ASC' AND @SortBy IN ('CreatedDate', 'CreatedDateFormat') THEN cat.CreatedDate END ASC,
				CASE WHEN @SortOrder = 'DESC' AND @SortBy IN ('CreatedDate', 'CreatedDateFormat') THEN cat.CreatedDate END DESC,
				cat.CreatedDate DESC
			OFFSET(@PageIndex - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY
			)
		SELECT p.CatalogueId
			,p.CatalogueName
			,p.CreatedDate
			,p.CreatedUTCDate
			,p.ProductPriceType
			,p.CreatedBy
			,p.CreatedName
			,ISNULL(v.ViewCount, 0) AS ViewCount
			,ISNULL(d.ProductCount, 0) AS ProductCount
			,p.TotalCount
		FROM PagedCatalogues p
		OUTER APPLY (
			SELECT COUNT(1) AS ViewCount
			FROM CatalogueAnonymousViews av WITH (NOLOCK)
			WHERE av.CatalogueId = p.CatalogueId
			) v
		OUTER APPLY (
			SELECT COUNT(1) AS ProductCount
			FROM CatalogueDetails cd WITH (NOLOCK)
			INNER JOIN Products pr WITH (NOLOCK) ON cd.ProductId = pr.ProductId
				AND pr.TenantId = @TenantId
				AND pr.STATUS <> 3
			INNER JOIN Categories c WITH (NOLOCK) ON pr.CategoryId = c.CategoryId
				AND c.IsDeleted = 0
				AND c.TenantId = @TenantId
			WHERE cd.CatalogueId = p.CatalogueId
				AND cd.IsDeleted = 0
			) d;

	END TRY

	BEGIN CATCH
		    
		IF @@TRANCOUNT > 0
			ROLLBACK;

		DECLARE @ObjectName VARCHAR(500)       
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName       
			,@ErrorMsg = @ErrorMsg;
	 
	END CATCH
END

GO

