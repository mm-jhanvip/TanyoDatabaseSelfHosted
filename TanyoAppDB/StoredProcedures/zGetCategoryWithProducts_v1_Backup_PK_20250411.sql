/*
EXEC GetCategoryWithProducts_v1
@TenantId = 1
,@RoleId = ''
,@OfferApplied = 0
,@CategoryId = '60542,2'
,@PriceFrom = NULL
,@PriceTo= NULL
,@PageIndex = 1
,@PageSize = 10
*/
CREATE PROCEDURE [dbo].[zGetCategoryWithProducts_v1_Backup_PK_20250411]
(
	@TenantId INT
	,@RoleId NVARCHAR(50)
	,@OfferApplied BIT = 0
	,@CategoryID NVARCHAR(MAX) = NULL
	,@PriceFrom DECIMAL(18, 2) = NULL
	,@PriceTo DECIMAL(18, 2) = NULL
	,@SortBy VARCHAR(50) = 'CostPrice'
	,@SortOrder VARCHAR(4) = 'DESC'
	,@PageIndex INT = 1
	,@PageSize INT = 25
	,@ProductIDs VARCHAR(MAX) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CategoryIdTable TABLE
	(
		CategoryId INT
		,CategoryName VARCHAR(50)
		,RowNum INT
	);
	DECLARE @ProductIDTable TABLE
	(
		ProductID BIGINT
	)
	DECLARE @jsonResult VARCHAR(MAX);

	INSERT INTO @CategoryIdTable (
		CategoryId
		,CategoryName
		,RowNum
		)
	SELECT CategoryId
		,CategoryName
		,ROW_NUMBER() OVER (ORDER BY CategoryId) AS RowNum
	FROM Categories as c WITH (NOLOCK)
	WHERE c.TenantId = @TenantId
	AND ( c.CategoryId IN (SELECT value FROM STRING_SPLIT(@CategoryID, ',')) OR @CategoryID IS NULL)
	AND IsDeleted = 0

	INSERT INTO @ProductIDTable (ProductID)
	SELECT value 
	FROM STRING_SPLIT(@ProductIDs, ',')

	DECLARE @CurrentCategoryId INT
	DECLARE @CurrentRow INT = 1

	DECLARE @dt DATE = CAST(GETDATE() AS DATE)
	DECLARE @HasWholesalerPrice BIT = 0;

	SELECT @HasWholesalerPrice = CASE WHEN EXISTS (
        SELECT 1 
        FROM AspNetRoleClaims WITH (NOLOCK)
        WHERE RoleId = @RoleId
        AND ClaimValue = 'Permissions.App.Order.WholeselerPrice'
    ) THEN 1 ELSE 0 END;

	IF @OfferApplied = 1
	BEGIN
		;WITH cteOffers
		AS (
			SELECT opm.ProductId
				,opm.OfferId
				,ofr.StartDate
				,ofr.EndDate
				,ofr.OfferPercentage
				,ofr.OfferCode
				,ofr.OfferTitle
			FROM dbo.OfferProductMapping AS opm WITH (NOLOCK)
			INNER JOIN dbo.Offers AS ofr WITH (NOLOCK) ON opm.OfferId = ofr.OfferId
			WHERE ofr.IsDeleted = 0
			AND ofr.TenantId = @TenantId
			AND ofr.StartDate <= @dt
			AND ofr.EndDate >= @dt
			GROUP BY opm.ProductId
				,opm.OfferId
				,ofr.StartDate
				,ofr.EndDate
				,ofr.OfferPercentage
				,ofr.OfferCode
				,ofr.OfferTitle
			)
		SELECT c.CategoryId
			,c.CategoryName
			,(
				SELECT TOP 5 p.ProductId
					,p.CategoryId
					,c.CategoryName
					,p.ProductTitle
					,p.ModelNo
					,p.Height
					,p.Width
					,p.Depth
					,COALESCE(
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							AND tp.IsCover = 1
							ORDER BY CreatedDate DESC
						),
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							ORDER BY CreatedDate DESC
						)
					)  AS CoverImage
					,COALESCE(
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							AND tp.IsCover = 1
							ORDER BY CreatedDate DESC
						),
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							ORDER BY CreatedDate DESC
						)
					)  AS productImage
					,ISNULL(ofr.OfferCode,'') AS OfferCode
					,1 AS OfferTag
					,ofr.OfferPercentage
					,p.CostPrice AS originalPrice
					,CASE 
						WHEN ofr.OfferId IS NOT NULL
							THEN dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage)
						ELSE 0
						END AS OfferPrice
					,ofr.OfferTitle
					,ofr.OfferId
					,dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, c.CategoryId) AS costPrice
					,p.CostPrice AS instantCostPrice
				FROM Products AS p WITH (NOLOCK)
				INNER JOIN cteOffers AS ofr WITH (NOLOCK) ON ofr.ProductId = p.ProductId
				WHERE p.CategoryId = c.CategoryId
				AND p.Status = 1
				AND (@PriceFrom IS NULL OR dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) >= @PriceFrom)
				AND (@PriceTo IS NULL OR dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) <= @PriceTo)
				AND (@ProductIDs IS NULL OR EXISTS (SELECT ProductID FROM @ProductIDTable WHERE p.ProductId = ProductID))
				ORDER BY ISNULL(p.UpdatedUTCDate, p.CreatedUTCDate) DESC
					,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'ASC' THEN dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) END
					,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'DESC' THEN dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) END DESC
				FOR JSON PATH
				) AS productListThumbnails
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM @CategoryIdTable c
		WHERE EXISTS
		(
			SELECT p.CategoryID
			FROM Products AS p WITH (NOLOCK)
			INNER JOIN cteOffers AS ofr WITH (NOLOCK) ON ofr.ProductId = p.ProductId
			WHERE p.CategoryId = c.CategoryId
			AND p.Status = 1
			AND (@PriceFrom IS NULL OR dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) >= @PriceFrom)
			AND (@PriceTo IS NULL OR dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, p.CategoryId), ofr.OfferPercentage) <= @PriceTo)
			AND (@ProductIDs IS NULL OR EXISTS (SELECT ProductID FROM @ProductIDTable WHERE p.ProductId = ProductID))
		)
		ORDER BY c.CategoryName
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;
	END
	ELSE
	BEGIN
		SELECT c.CategoryId
			,c.CategoryName
			,(
				SELECT TOP 5 p.ProductId
					,p.CategoryId
					,c.CategoryName
					,p.ProductTitle
					,p.ModelNo
					,p.Height
					,p.Width
					,p.Depth
					,COALESCE(
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							AND tp.IsCover = 1
							ORDER BY CreatedDate DESC
						),
						(
							SELECT TOP 1 ImagePath
							FROM ProductImages tp WITH (NOLOCK)
							WHERE tp.ProductId = p.productId
							ORDER BY CreatedDate DESC
						)
					) AS productImage
					,0 AS offerTag
					,0 AS offerPercentage
					,0 AS originalPrice
					,0 AS OfferPrice
					,NULL AS offerTitle
					,NULL AS offerId
					,CAST(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, c.CategoryId) AS DECIMAL) AS costPrice
					,NULL AS instantCostPrice
				FROM Products AS p WITH (NOLOCK)
				WHERE p.CategoryId = c.CategoryId
				AND p.Status = 1
				AND (@PriceFrom IS NULL OR case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end >= @PriceFrom)
				AND (@PriceTo IS NULL OR case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end <= @PriceTo)
				AND (@ProductIDs IS NULL OR EXISTS (SELECT ProductID FROM @ProductIDTable WHERE p.ProductId = ProductID))
				ORDER BY ISNULL(p.UpdatedUTCDate, p.CreatedUTCDate) DESC
					,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'ASC' THEN case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end END
					,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'DESC' THEN case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end END DESC
				FOR JSON PATH
				) AS productListThumbnails
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM @CategoryIdTable AS c
		WHERE EXISTS
		(
			SELECT p.CategoryID
			FROM Products AS p WITH (NOLOCK)
			WHERE p.CategoryId = c.CategoryId
			AND p.Status = 1
			AND (@PriceFrom IS NULL OR case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end >= @PriceFrom)
			AND (@PriceTo IS NULL OR case when @HasWholesalerPrice = 1 then p.WholesalerPrice else p.RetailerPrice end <= @PriceTo)
			AND (@ProductIDs IS NULL OR EXISTS (SELECT ProductID FROM @ProductIDTable WHERE p.ProductId = ProductID))
		)
		ORDER BY c.CategoryName
		OFFSET (@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;
	END
END

GO

