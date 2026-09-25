CREATE   PROC [dbo].[ReportUnsoldInventory] (
	@TenantId INT
	,@PeriodInMonth INT
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@SortBy VARCHAR(50) = 'TotalAmount'
	,@SortOrder VARCHAR(50) = 'DESC'
	,@OfferId INT = NULL
	,@ProductName VARCHAR(256) = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL
		DROP TABLE #Offers

	IF OBJECT_ID('tempdb..#UnsoldProducts') IS NOT NULL
		DROP TABLE #UnsoldProducts

	DECLARE @date DATETIME = GETDATE()
	DECLARE @ProductSubjectTypeId INT;

	SELECT @ProductSubjectTypeId = SubjectTypeId
	FROM SubjectTypes WITH (NOLOCK)
	WHERE SubjectTypeName = 'Products'
		AND TenantId = @TenantId
		AND IsDeleted = 0

	BEGIN TRY
		CREATE TABLE #Offers (
			[Seq] [int] IDENTITY(1, 1) NOT NULL
			,[ProductId] [bigint] NOT NULL
			,[OfferId] [int] NOT NULL
			,[StartDate] [date] NOT NULL
			,[EndDate] [date] NOT NULL
			,[OfferPercentage] [int] NOT NULL
			,[OfferCode] [varchar](50) NOT NULL
			)

		SELECT p.ProductId AS 'ProductId'
			,p.CoverImage AS CoverImage
			,p.ModelNo AS 'ModelNo'
			,p.ProductTitle + ' - ' + p.ModelNo AS 'ProductTitle'
			,pq.Quantity AS 'Quantity'
			,p.CostPrice AS 'CostPrice'
			,(pq.Quantity * p.CostPrice) AS 'TotalAmount'
			,p.VendorNames AS VendorNames
			,pq.LastModifiedDate AS 'LastModifiedDate'
			,p.RetailerPrice
			,ISNULL(p.RetailOfferPrice, 0) [OfferPrice]
		INTO #UnsoldProducts
		FROM Products p WITH (NOLOCK)
		INNER JOIN ProductQuantities pq WITH (NOLOCK) ON pq.ProductId = p.ProductId
		WHERE pq.Quantity > 0
			AND p.TenantId = @TenantId
			AND p.Status = 1
			AND NOT EXISTS (
				SELECT 1
				FROM OrderSetItems osi WITH (NOLOCK)
				INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
				WHERE p.ProductId = osi.SubjectId
					AND o.TenantId = @TenantId
					AND osi.SubjectTypeId = @ProductSubjectTypeId
					AND o.Status NOT IN (
						6
						,8
						,9
						)
					AND osi.CreatedDate BETWEEN DATEADD(MONTH, - (@PeriodInMonth), @date)
						AND @date
				)
			AND (
				@ProductName IS NULL
				OR p.ProductTitle + ' - ' + p.ModelNo LIKE '%' + @ProductName + '%'
				)

		INSERT INTO #Offers (
			ProductId
			,OfferId
			,StartDate
			,EndDate
			,OfferPercentage
			,OfferCode
			)
		SELECT opm.ProductId
			,opm.OfferId
			,ofr.StartDate
			,ofr.EndDate
			,ofr.OfferPercentage
			,ofr.OfferCode
		FROM dbo.OfferProductMapping AS OPM WITH (NOLOCK)
		INNER JOIN dbo.Offers AS ofr WITH (NOLOCK) ON opm.offerId = ofr.OfferId
		INNER JOIN #UnsoldProducts USP ON OPM.ProductId = USP.ProductId
		WHERE ofr.IsDeleted = 0
			AND ofr.TenantId = @TenantId
			AND (
				@OfferId IS NULL
				OR @OfferId = - 2
				OR OFR.OfferId = @OfferId
				)
		GROUP BY opm.ProductId
			,opm.OfferId
			,ofr.StartDate
			,ofr.EndDate
			,ofr.OfferPercentage
			,ofr.OfferCode

		SELECT UP.ProductId
			,UP.CoverImage
			,UP.ModelNo
			,UP.ProductTitle
			,UP.Quantity
			,UP.CostPrice
			,UP.TotalAmount
			,UP.VendorNames
			,UP.LastModifiedDate
			,UP.RetailerPrice
			,ofr.OfferId
			,ofr.OfferCode AS OfferCode
			,UP.OfferPrice
			,CASE 
				WHEN ofr.OfferId IS NOT NULL
					AND ofr.StartDate <= @date
					AND ofr.EndDate >= @date
					THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
				END AS ExpiredOffer
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM #UnsoldProducts UP
		LEFT JOIN #Offers OFR ON OFR.ProductId = UP.ProductId
		WHERE (
				-- Normal behavior
				@OfferId IS NULL
				OR OFR.OfferId = @OfferId
				-- Only products WITHOUT offers
				OR (
					@OfferId = - 2
					AND OFR.OfferId IS NULL
					)
				)
		ORDER BY CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'ASC'
					THEN UP.ProductTitle
				END ASC
			,CASE 
				WHEN @SortBy = 'ProductTitle'
					AND @SortOrder = 'DESC'
					THEN UP.ProductTitle
				END DESC
			,CASE 
				WHEN @SortBy = 'Quantity'
					AND @SortOrder = 'ASC'
					THEN UP.Quantity
				END ASC
			,CASE 
				WHEN @SortBy = 'Quantity'
					AND @SortOrder = 'DESC'
					THEN UP.Quantity
				END DESC
			,CASE 
				WHEN @SortBy = 'CostPrice'
					AND @SortOrder = 'ASC'
					THEN UP.CostPrice
				END ASC
			,CASE 
				WHEN @SortBy = 'CostPrice'
					AND @SortOrder = 'DESC'
					THEN UP.CostPrice
				END DESC
			,CASE 
				WHEN @SortBy = 'RetailerPrice'
					AND @SortOrder = 'ASC'
					THEN UP.RetailerPrice
				END ASC
			,CASE 
				WHEN @SortBy = 'RetailerPrice'
					AND @SortOrder = 'DESC'
					THEN UP.RetailerPrice
				END DESC
			,CASE 
				WHEN @SortBy = 'OfferPrice'
					AND @SortOrder = 'ASC'
					THEN UP.OfferPrice
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferPrice'
					AND @SortOrder = 'DESC'
					THEN UP.OfferPrice
				END DESC
			,CASE 
				WHEN @SortBy = 'TotalAmount'
					AND @SortOrder = 'ASC'
					THEN UP.TotalAmount
				END ASC
			,CASE 
				WHEN @SortBy = 'TotalAmount'
					AND @SortOrder = 'DESC'
					THEN UP.TotalAmount
				END DESC
			,CASE 
				WHEN @SortBy = 'LastModifiedDate'
					AND @SortOrder = 'ASC'
					THEN UP.LastModifiedDate
				END ASC
			,CASE 
				WHEN @SortBy = 'LastModifiedDate'
					AND @SortOrder = 'DESC'
					THEN UP.LastModifiedDate
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

