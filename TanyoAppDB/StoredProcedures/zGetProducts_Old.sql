--[GetProducts] @TenantId=1, @RoleId='555D131D-3306-40AC-9A7B-6CBDA78A1C2F'
CREATE PROCEDURE [dbo].[zGetProducts_Old] (
	@TenantId INT
	,@CategoryId BIGINT = NULL
	,@RoleId VARCHAR(100)
	,@ProductTitle VARCHAR(100) = NULL
	,@ModelNo VARCHAR(100) = NULL
	,@PublishStatus INT = NULL
	,@OfferDataId INT = NULL
	,@UpdateFromDate DATE = NULL
	,@UpdateToDate DATE = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = '10'
	,@SortOrder VARCHAR(50) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @ProductSubjectTypeId INT;
	DECLARE @dt DATE
	SELECT @dt = CAST(GETDATE() AS DATE)

	SELECT @ProductSubjectTypeId = SubjectTypeId
	FROM SubjectTypes WITH (NOLOCK)
	WHERE SubjectTypeName = 'Products'
		AND TenantId = @TenantId
		AND IsDeleted = 0

	BEGIN TRY
		;with cteOffers as(
			SELECT	opm.ProductId, opm.OfferId, ofr.StartDate, ofr.EndDate, ofr.OfferPercentage
			FROM	dbo.OfferProductMapping AS opm WITH (NOLOCK) 
			INNER JOIN dbo.Offers AS ofr WITH (NOLOCK) ON opm.offerId = ofr.OfferId
			WHERE ofr.IsDeleted = 0
			AND ofr.TenantId = @TenantId
			GROUP BY opm.ProductId, opm.OfferId, ofr.StartDate, ofr.EndDate, ofr.OfferPercentage
		)
		SELECT p.ProductId
			,CAST(CONVERT(BIGINT, t.CategoryId) AS INT) AS CategoryId
			,t.CategoryName
			,p.ProductTitle
			,ROUND(p.CostPrice, 0) AS CostPrice
			,dbo.CalculateFinalCostPrice(p.ProductId, 0, 1, @RoleId, @TenantId, t.CategoryId) [WholeSalerPrice]
			,dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, t.CategoryId) [RetailerPrice]
			,CASE 
				WHEN ofr.OfferId IS NOT NULL
					THEN (dbo.CalculateTotalOfferAmount(dbo.CalculateFinalCostPrice(p.ProductId, 0, 0, @RoleId, @TenantId, t.CategoryId), ofr.OfferPercentage))
				ELSE 0
				END [OfferPrice]
			,(
				SELECT TOP 1 ImagePath
				FROM ProductImages tp
				WHERE tp.ProductId = p.ProductId
				and tp.IsCover=1
				ORDER BY CreatedDate DESC
				) CoverImage
			,p.ModelNo
			,p.STATUS
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
			,ISNULL(ia.Quantity, 0) AS InStock
			--,0 AS ReadyToDelivered
			--,0 AS Inquiry
			,ISNULL((SELECT SUM(os.Quantity)
				FROM dbo.Orders AS o WITH (NOLOCK) 
				INNER JOIN dbo.OrderSetItems AS os WITH (NOLOCK) ON os.OrderId = o.OrderId
				WHERE os.ItemStatus = 2
					and o.TenantId = @TenantId
							AND o.STATUS > 2
							AND o.STATUS NOT IN (
								8
								,9
								)
							AND os.IsDeleted != 1
							and os.SubjectId = p.ProductId
				),0)
				AS ReadyToDelivered
			,ISNULL((SELECT SUM(os.Quantity)
				FROM dbo.Orders AS o WITH (NOLOCK) 
				INNER JOIN dbo.OrderSetItems AS os WITH (NOLOCK) ON os.OrderId = o.OrderId
				WHERE p.ProductId = os.SubjectId
				and o.TenantId = @TenantId
				AND o.STATUS = 0
				AND os.IsDeleted != 1
				AND o.STATUS != 9
				AND os.SubjectTypeId = @ProductSubjectTypeId
						),0) AS Inquiry
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM dbo.Products AS p WITH (NOLOCK)
		INNER JOIN dbo.Categories AS t WITH (NOLOCK) ON p.CategoryId = t.CategoryId
		INNER JOIN dbo.AspNetUsers AS [as] WITH (NOLOCK) ON p.CreatedBy = [as].UserId
		LEFT JOIN dbo.ProductQuantities AS ia WITH (NOLOCK) ON p.ProductId = ia.ProductId
		LEFT JOIN cteOffers ofr ON ofr.ProductId = p.ProductId
		WHERE p.TenantId = @TenantId
			AND p.STATUS <> 3
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
				ISNULL(@OfferDataId, - 1) = - 1
				OR ofr.OfferId = @OfferDataId
				)
			AND (
				@UpdateFromDate IS NULL
				OR @UpdateToDate IS NULL
				OR p.UpdatedDate BETWEEN @UpdateFromDate
					AND @UpdateToDate
				)
		ORDER BY CASE 
				WHEN @SortBy = 'CategoryName'
					AND @SortOrder = 'ASC'
					THEN t.CategoryName
				END ASC
			,CASE 
				WHEN @SortBy = 'CategoryName'
					AND @SortOrder = 'DESC'
					THEN t.CategoryName
				END DESC
			,CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'ASC'
					THEN p.ProductTitle
				END ASC
			,CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'DESC'
					THEN p.ProductTitle
				END DESC
			,CASE 
				WHEN @SortBy = 'ModelNo'
					AND @SortOrder = 'ASC'
					THEN p.ModelNo
				END ASC
			,CASE 
				WHEN @SortBy = 'ModelNo'
					AND @SortOrder = 'DESC'
					THEN p.ModelNo
				END DESC
			,CASE 
				WHEN @SortBy = 'CostPrice'
					AND @SortOrder = 'ASC'
					THEN ROUND(p.CostPrice, 0)
				END ASC
			,CASE 
				WHEN @SortBy = 'CostPrice'
					AND @SortOrder = 'DESC'
					THEN ROUND(p.CostPrice, 0)
				END DESC
			,CASE 
				WHEN @SortBy = 'UpdatedDate'
					AND @SortOrder = 'ASC'
					THEN p.UpdatedDate
				END ASC
			,CASE 
				WHEN @SortBy = 'UpdatedDate'
					AND @SortOrder = 'DESC'
					THEN p.UpdatedDate
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;

	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

