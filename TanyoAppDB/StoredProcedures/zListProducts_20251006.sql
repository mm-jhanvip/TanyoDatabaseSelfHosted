/*
	EXEC [dbo].[ListProducts] 
        @TenantId = 84,
        @CategoryId = NULL,
        @RoleId = '30EE75B3-B26F-4D61-A91B-51C7E78E422E', 
		@IsOfferedProduct = 0,
        @ProductTitle= NULL, 
        @ModelNo= NULL,
        @PublishStatus= NULL,
        @OfferDataId= NULL, 
        @UpdateFromDate= NULL,
        @UpdateToDate= NULL, 
		@VendorId = NULL,
		@FromPrice = NULL,
		@ToPrice = NULL,
		@Quantity = NULL,
		@StockFilterOperation= NULL,
        @PageIndex = 1, 
        @PageSize = 50, 
        @SortBy = NULL,
        @SortOrder= NULL		
*/

CREATE PROCEDURE [dbo].[zListProducts_20251006]
(
	@TenantId INT
	,@CategoryId BIGINT = NULL
	,@RoleId VARCHAR(100)
	,@ProductTitle VARCHAR(100) = NULL
	,@ModelNo VARCHAR(100) = NULL
	,@PublishStatus INT = NULL
	,@OfferDataId INT = NULL
	,@UpdateFromDate DATE = NULL
	,@UpdateToDate DATE = NULL
	,@VendorId BIGINT = NULL
	,@FromPrice INT = NULL
	,@ToPrice INT = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = '10'
	,@SortOrder VARCHAR(50) = 'DESC'
	,@IsOfferedProduct BIT = 0
	,@Quantity INT = NULL
	,@StockFilterOperation VARCHAR(5) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @dt DATE
	SELECT @dt = CAST(GETDATE() AS DATE)

	BEGIN TRY
	
		DROP TABLE IF EXISTS #cteOffers
		CREATE TABLE #cteOffers
		(
			[Seq] [int] IDENTITY(1,1) NOT NULL 
			,[ProductId] [bigint] NOT NULL PRIMARY KEY
			,[OfferId] [int] NOT NULL 
			,[StartDate] [date] NOT NULL
			,[EndDate] [date] NOT NULL
			,[OfferPercentage] [int] NOT NULL
			,[OfferCode] [varchar](50) NOT NULL
		)

		INSERT INTO #cteOffers (ProductId, OfferId, StartDate, EndDate, OfferPercentage, OfferCode)
		SELECT opm.ProductId, opm.OfferId, ofr.StartDate, ofr.EndDate, ofr.OfferPercentage, ofr.OfferCode
		FROM dbo.OfferProductMapping AS opm WITH (NOLOCK) 
		INNER JOIN dbo.Offers AS ofr WITH (NOLOCK) ON opm.offerId = ofr.OfferId
		WHERE ofr.IsDeleted = 0
		AND ofr.TenantId = @TenantId
		GROUP BY opm.ProductId, opm.OfferId, ofr.StartDate, ofr.EndDate, ofr.OfferPercentage, ofr.OfferCode
		
		IF(@IsOfferedProduct = 0)
		BEGIN
			SELECT p.ProductId
				,CAST(CONVERT(BIGINT, t.CategoryId) AS INT) AS CategoryId
				,t.CategoryName
				,p.ProductTitle
				,pv.VendorName
				,ROUND(p.CostPrice, 0) AS CostPrice
				,p.WholesalerPrice AS [WholeSalerPrice]
				,p.RetailerPrice AS [RetailerPrice]
				,ISNULL(p.RetailOfferPrice, 0) [OfferPrice]
				,ISNULL(p.CoverImage, '') CoverImage
				,p.ModelNo
				,p.Status
				,CASE 
					WHEN p.UpdatedBy IS NOT NULL
						THEN p.UpdatedBy
					ELSE p.CreatedBy
					END AS UpdatedBy
				,CASE 
					WHEN p.UpdatedDate IS NOT NULL
						THEN p.UpdatedDate
					ELSE p.CreatedDate
					END AS CreatedDate
				,ofr.OfferId
				,ofr.OfferCode as OfferCode
				,pq.Quantity
				,CASE 
					WHEN ofr.OfferId IS NOT NULL 
							AND ofr.StartDate <= @dt
							AND ofr.EndDate >= @dt
						THEN CAST(0 AS BIT)
					ELSE CAST(1 AS BIT)
				END AS ExpiredOffer
				,t.IsSellByPerSQFT
				,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
			FROM dbo.Products AS p WITH (NOLOCK)
			INNER JOIN dbo.ProductQuantities AS pq WITH (NOLOCK) ON p.ProductId = pq.ProductId
			INNER JOIN dbo.Categories AS t WITH (NOLOCK) ON p.CategoryId = t.CategoryId
			LEFT JOIN #cteOffers ofr ON ofr.ProductId = p.ProductId
			LEFT JOIN (
				SELECT pvm.ProductId,
					   STRING_AGG(v.VendorName, ', ') AS VendorName
				FROM dbo.ProductVendorMapping AS pvm
				INNER JOIN dbo.Vendors AS v ON pvm.VendorId = v.VendorId
				WHERE ((@VendorId IS NULL) OR pvm.VendorId = @VendorId)
				GROUP BY pvm.ProductId
			) AS pv ON p.ProductId = pv.ProductId
			WHERE p.TenantId = @TenantId
			AND p.STATUS <> 3
			AND t.TenantId = @TenantId
			AND ((@FromPrice IS NULL OR @FromPrice = -1 OR p.RetailerPrice >= @FromPrice)) 
			AND ((@ToPrice IS NULL OR @ToPrice = -1 OR p.RetailerPrice <= @ToPrice))
			AND (
					@PublishStatus IS NULL
					OR p.STATUS = @PublishStatus
				)
			AND (
					ISNULL(@ModelNo, '') = ''
					OR p.ModelNo LIKE  '%' + @ModelNo + + '%'
				)
			AND (
					ISNULL(@CategoryId, - 1) = - 1
					OR p.CategoryId = @CategoryId
				)
			AND (
					ISNULL(@ProductTitle, '') = ''
					OR p.ProductTitle LIKE  '%' + @ProductTitle + '%'
				)
			AND (
					(ISNULL(@OfferDataId, - 1) = - 1 OR ofr.OfferId = @OfferDataId)
					OR (ISNULL(@OfferDataId, - 1) = -2 AND ofr.OfferId IS NULL)
				)
			AND (
					@UpdateFromDate IS NULL
					OR @UpdateToDate IS NULL
					OR p.UpdatedDate BETWEEN @UpdateFromDate
						AND @UpdateToDate
				)
			AND (
				ISNULL(@VendorId, - 1) = - 1
				OR EXISTS (
					SELECT pvm.ProductId FROM dbo.ProductVendorMapping AS pvm
						WHERE pvm.ProductId = p.ProductId
					AND pvm.VendorId = @VendorId )
				)
			AND (
					(@Quantity IS NULL OR @StockFilterOperation IS NULL) 
					OR (@StockFilterOperation = '=' AND pq.Quantity = @Quantity)
					OR (@StockFilterOperation = '>=' AND pq.Quantity >= @Quantity)
					OR (@StockFilterOperation = '<=' AND pq.Quantity <= @Quantity)
				)
			ORDER BY CASE WHEN @SortBy = 'CategoryName' AND @SortOrder = 'ASC' THEN t.CategoryName END ASC
				,CASE WHEN @SortBy = 'CategoryName' AND @SortOrder = 'DESC' THEN t.CategoryName END DESC
				,CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'ASC' THEN p.ProductTitle END ASC
				,CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'DESC' THEN p.ProductTitle END DESC
				,CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'ASC' THEN p.ModelNo END ASC
				,CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'DESC' THEN p.ModelNo END DESC
				,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'ASC' THEN ROUND(p.CostPrice, 0) END ASC
				,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'DESC' THEN ROUND(p.CostPrice, 0) END DESC
				,CASE WHEN @SortBy = 'UpdatedDate' AND @SortOrder = 'ASC' THEN p.UpdatedDate END ASC
				,CASE WHEN @SortBy = 'UpdatedDate' AND @SortOrder = 'DESC' THEN p.UpdatedDate END DESC 
				,CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'ASC' THEN pv.VendorName END ASC
				,CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'DESC' THEN pv.VendorName END DESC
			OFFSET(@PageIndex - 1) * @PageSize ROWS
			FETCH NEXT @PageSize ROWS ONLY;
		END
		ELSE
		BEGIN
			SELECT p.ProductId
				,CAST(CONVERT(BIGINT, t.CategoryId) AS INT) AS CategoryId
				,t.CategoryName
				,p.ProductTitle
				,pv.VendorName
				,ROUND(p.CostPrice, 0) AS CostPrice
				,p.WholesalerPrice AS [WholeSalerPrice]
				,p.RetailerPrice AS [RetailerPrice]
				,ISNULL(p.RetailOfferPrice, 0) [OfferPrice]
				,ISNULL(p.CoverImage, '') CoverImage
				,p.ModelNo
				,p.Status
				,CASE 
					WHEN p.UpdatedBy IS NOT NULL
						THEN p.UpdatedBy
					ELSE p.CreatedBy
					END AS UpdatedBy
				,CASE 
					WHEN p.UpdatedDate IS NOT NULL
						THEN p.UpdatedDate
					ELSE p.CreatedDate
					END AS CreatedDate
				,ofr.OfferId
				,ofr.OfferCode as OfferCode
				,pq.Quantity
				,CASE 
					WHEN ofr.OfferId IS NOT NULL 
							AND ofr.StartDate <= @dt
							AND ofr.EndDate >= @dt
						THEN CAST(0 AS BIT)
					ELSE CAST(1 AS BIT)
				END AS ExpiredOffer
				,t.IsSellByPerSQFT
				,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
			FROM dbo.Products AS p WITH (NOLOCK)
			INNER JOIN dbo.ProductQuantities AS pq WITH (NOLOCK) ON p.ProductId = pq.ProductId
			INNER JOIN dbo.Categories AS t WITH (NOLOCK) ON p.CategoryId = t.CategoryId
			INNER JOIN #cteOffers ofr ON ofr.ProductId = p.ProductId
			LEFT JOIN (
				SELECT pvm.ProductId,
					   STRING_AGG(v.VendorName, ', ') AS VendorName
				FROM dbo.ProductVendorMapping AS pvm
				INNER JOIN dbo.Vendors AS v ON pvm.VendorId = v.VendorId
				WHERE ((@VendorId IS NULL) OR pvm.VendorId = @VendorId)
				GROUP BY pvm.ProductId
			) AS pv ON p.ProductId = pv.ProductId
			WHERE p.TenantId = @TenantId
			AND p.STATUS <> 3
			AND t.TenantId = @TenantId
			AND ((@FromPrice IS NULL OR @FromPrice = -1 OR p.RetailerPrice >= @FromPrice)) 
			AND ((@ToPrice IS NULL OR @ToPrice = -1 OR p.RetailerPrice <= @ToPrice))
			AND (
					@PublishStatus IS NULL
					OR p.STATUS = @PublishStatus
				)
			AND (
					ISNULL(@ModelNo, '') = ''
					OR p.ModelNo LIKE  '%' + @ModelNo + + '%'
				)
			AND (
					ISNULL(@CategoryId, - 1) = - 1
					OR p.CategoryId = @CategoryId
				)
			AND (
					ISNULL(@ProductTitle, '') = ''
					OR p.ProductTitle LIKE  '%' + @ProductTitle + '%'
				)
			AND (
					ISNULL(@OfferDataId, - 1) IN (-1, -2)
					OR ofr.OfferId = @OfferDataId
				)
			AND (
					@UpdateFromDate IS NULL
					OR @UpdateToDate IS NULL
					OR p.UpdatedDate BETWEEN @UpdateFromDate
						AND @UpdateToDate
				)
			AND (
				ISNULL(@VendorId, - 1) = - 1
				OR EXISTS (
					SELECT pvm.ProductId FROM dbo.ProductVendorMapping AS pvm
						WHERE pvm.ProductId = p.ProductId
					AND pvm.VendorId = @VendorId )
				)
			AND (
					(@Quantity IS NULL OR @StockFilterOperation IS NULL) 
					OR (@StockFilterOperation = '=' AND pq.Quantity = @Quantity)
					OR (@StockFilterOperation = '>=' AND pq.Quantity >= @Quantity)
					OR (@StockFilterOperation = '<=' AND pq.Quantity <= @Quantity)
				)
			ORDER BY CASE WHEN @SortBy = 'CategoryName' AND @SortOrder = 'ASC' THEN t.CategoryName END ASC
				,CASE WHEN @SortBy = 'CategoryName' AND @SortOrder = 'DESC' THEN t.CategoryName END DESC
				,CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'ASC' THEN p.ProductTitle END ASC
				,CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'DESC' THEN p.ProductTitle END DESC
				,CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'ASC' THEN p.ModelNo END ASC
				,CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'DESC' THEN p.ModelNo END DESC
				,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'ASC' THEN ROUND(p.CostPrice, 0) END ASC
				,CASE WHEN @SortBy = 'CostPrice' AND @SortOrder = 'DESC' THEN ROUND(p.CostPrice, 0) END DESC
				,CASE WHEN @SortBy = 'UpdatedDate' AND @SortOrder = 'ASC' THEN p.UpdatedDate END ASC
				,CASE WHEN @SortBy = 'UpdatedDate' AND @SortOrder = 'DESC' THEN p.UpdatedDate END DESC 
				,CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'ASC' THEN pv.VendorName END ASC
				,CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'DESC' THEN pv.VendorName END DESC
			OFFSET(@PageIndex - 1) * @PageSize ROWS
			FETCH NEXT @PageSize ROWS ONLY;
		END
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState)
	END CATCH
END

GO

