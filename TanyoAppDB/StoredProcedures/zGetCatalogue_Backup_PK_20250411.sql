
-- =============================================
-- Author		: MagnusMinds
-- Create date	: 07-05-2024
-- Description	: GetCatalogue
-- =============================================
/*
EXEC [dbo].[GetCatalogue]
	  @CategoryId = 7
	 ,@RoleId = '0FC94370-F8D9-4AAD-8314-98140AEDE101'
	 ,@Offer = '0'
	 ,@Search = ''
	 ,@TenantId = 1
	 ,@PageIndex = 1
	 ,@PageSize = 66
	 ,@SortBy = 'PriceHighToLow'
	 ,@SortOrder = 'DESC'
	 ,@PriceFrom = 5000
	 ,@PriceTo = 25000
*/
CREATE PROCEDURE [dbo].[zGetCatalogue_Backup_PK_20250411]
(
	@CategoryId INT
	,@RoleId VARCHAR(MAX) 
	,@Offer VARCHAR(MAX) = ''
	,@Search VARCHAR(MAX) = ''
	,@TenantId INT
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@SortBy VARCHAR(100) = ''
	,@SortOrder VARCHAR(100) = ''
	,@PriceFrom DECIMAL(18, 2) = NULL
	,@PriceTo DECIMAL(18, 2) = NULL
	,@ProductIDs VARCHAR(MAX) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN 
		DECLARE @dt DATE
		select @dt = CAST(GETDATE() AS DATE)
		DECLARE @ProductSubjectTypeId BIGINT

		DECLARE @ProductIDTable TABLE
		(
			ProductID BIGINT
		)

		INSERT INTO @ProductIDTable (ProductID)
		SELECT value 
		FROM STRING_SPLIT(@ProductIDs, ',')
		
		DROP TABLE IF EXISTS #TempTableProductImages

		CREATE TABLE #TempTableProductImages
		(
			ProductId BIGINT NOT NULL
			,ImagePath VARCHAR(MAX) NULL
			,CreatedUTCDate DATETIME
			,IsCover BIT
		)

		INSERT INTO #TempTableProductImages
		(
			ProductId
			,ImagePath
			,CreatedUTCDate
			,IsCover
		)
		SELECT im.ProductId
			,im.ImagePath
			,im.CreatedUTCDate
			,im.IsCover
		FROM ProductImages im WITH (NOLOCK)
		INNER JOIN Products p ON p.ProductId = im.Productid
		WHERE p.TenantId = @TenantId

		SELECT @ProductSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'Products'

		SELECT c.CategoryId [CategoryId]
		    ,p.ProductId [ProductId]	
			,c.CategoryName [CategoryName]
			,p.ProductTitle [ProductTitle]
			,COALESCE(
				(
					SELECT TOP 1 ImagePath
					FROM #TempTableProductImages tp
					WHERE tp.ProductId = p.productId
					AND tp.IsCover = 1
					ORDER BY tp.CreatedUTCDate DESC
				),
				(
					SELECT TOP 1 ImagePath
					FROM #TempTableProductImages tp
					WHERE tp.ProductId = p.productId
					ORDER BY tp.CreatedUTCDate DESC
				)
			) ProductImage
			,p.ModelNo [ModelNo]
			,CASE 
				WHEN o.OfferId IS NOT NULL
					AND (CAST(o.StartDate AS DATE) <= @dt
					AND CAST(o.EndDate AS DATE) >= @dt)
					THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId), o.OfferPercentage))
				ELSE dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId)
				END [CostPrice]
			,CASE 
				WHEN CAST(o.StartDate AS DATE) <= @dt
					AND CAST(o.EndDate AS DATE) >= @dt
					THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
				END [OfferTag]
			,CASE 
				WHEN CAST(o.StartDate AS DATE) <= @dt
					AND CAST(o.EndDate AS DATE) >= @dt
					THEN o.OfferCode
				ELSE ''
				END [OfferCode]
			,st.SubjectTypeId [SubjectTypeId]
			,p.Height [Height]
			,p.Width [Width]
			,p.Depth [Depth]
			,p.Diameter [Diameter]
			,p.Features [Description]
			,p.FabricNeeded [FabricNeeded]
			,dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId) [OriginalPrice]
			,o.OfferPercentage [offerPercentage]
			,o.OfferTitle [OfferTitle]
			,CASE 
				WHEN CAST(o.StartDate AS DATE) <= @dt
					AND CAST(o.EndDate AS DATE) >= @dt
					THEN ofm.OfferId
				ELSE NULL
				END [OfferId]
			,p.CostPrice [InstantCostPrice]
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM Categories c
		INNER JOIN Products p ON c.CategoryId = p.CategoryId
			AND p.TenantId = @TenantId
			AND c.TenantId = @TenantId
			AND c.CategoryId = @CategoryId
			AND c.IsDeleted = 0
			AND p.STATUS = 1
		INNER JOIN SubjectTypes st ON st.TenantId = @TenantId
			AND st.SubjectTypeId = @ProductSubjectTypeId
		LEFT JOIN OfferProductMapping ofm ON p.ProductId = ofm.ProductId
		LEFT JOIN Offers o ON ofm.OfferId = o.OfferId
			AND o.IsDeleted = 0
		WHERE   
		(@Offer = 0
			OR (@Offer = 1
					AND o.StartDate <= @dt
					AND o.EndDate  >= @dt
				)
		) 
		AND (@Search IS NULL OR @Search = ''
			OR (
				p.ProductTitle LIKE '%' + @Search + '%'
				OR p.ModelNo LIKE '%' + @Search + '%'
				OR CONCAT(p.ProductTitle, ' - ', p.ModelNo) LIKE '%' + @Search + '%'
				)
			)
		AND (@PriceFrom IS NULL OR (CASE 
							WHEN o.OfferId IS NOT NULL
								AND (CAST(o.StartDate AS DATE) <= @dt
								AND CAST(o.EndDate AS DATE) >= @dt)
								THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId), o.OfferPercentage))
							ELSE dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId)
						END) >= @PriceFrom)
		AND (@PriceTo IS NULL OR (CASE 
							WHEN o.OfferId IS NOT NULL
								AND (CAST(o.StartDate AS DATE) <= @dt
								AND CAST(o.EndDate AS DATE) >= @dt)
								THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId), o.OfferPercentage))
							ELSE dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId)
						END) <= @PriceTo)
		AND (@ProductIDs IS NULL OR EXISTS (SELECT ProductID FROM @ProductIDTable WHERE p.ProductId = ProductID))
		ORDER BY ISNULL(p.UpdatedUTCDate, p.CreatedUTCDate) DESC
			,CASE 
				WHEN @SortBy = 'CategoryId'
					AND @SortOrder = 'ASC'
					THEN c.CategoryId
				END ASC
			,CASE 
				WHEN @SortBy = 'CategoryId'
					AND @SortOrder = 'DESC'
					THEN c.CategoryId
				END DESC 
			,CASE 
				WHEN @SortBy = 'WhatsNew'
					AND @SortOrder = 'ASC'
					THEN p.CreatedDate
				END ASC 
			,CASE 
				WHEN @SortBy = 'WhatsNew'
					AND @SortOrder = 'DESC'
					THEN p.CreatedDate
				END DESC 
			,CASE 
				WHEN @SortBy = 'PriceHighToLow'
					AND @SortOrder = 'DESC'
					THEN 
						CASE 
							WHEN o.OfferId IS NOT NULL
								AND (CAST(o.StartDate AS DATE) <= @dt
								AND CAST(o.EndDate AS DATE) >= @dt)
								THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId), o.OfferPercentage))
							ELSE dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId)
						END
				END DESC
			,CASE 
				WHEN @SortBy = 'PriceLowToHigh'
					AND @SortOrder = 'ASC'
					THEN 
						CASE 
							WHEN o.OfferId IS NOT NULL
								AND (CAST(o.StartDate AS DATE) <= @dt
								AND CAST(o.EndDate AS DATE) >= @dt)
								THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId), o.OfferPercentage))
							ELSE dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, @CategoryId)
						END
				END ASC

		OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY; 

	END 
END

GO

