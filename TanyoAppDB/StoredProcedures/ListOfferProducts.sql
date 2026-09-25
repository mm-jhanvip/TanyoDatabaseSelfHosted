/*
EXEC [dbo].[ListOfferProducts] 
   @TenantId = 2
  ,@OfferId = 175
  ,@PageIndex = 1
  ,@PageSize = 100
  ,@SortBy = 'ProductTitle'
  ,@SortOrder = 'DESC'
GO
*/
CREATE PROCEDURE [dbo].[ListOfferProducts] (
	@TenantId INT
	,@OfferId INT
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'ProductTitle'
	,@SortOrder VARCHAR(50) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @dt DATE

	SELECT @dt = CAST(GETDATE() AS DATE)

	BEGIN TRY
		SELECT p.ProductId
			,ISNULL(p.CoverImage, '') CoverImage
			,p.ProductTitle
			,p.ModelNo
			,ROUND(p.CostPrice, 2) AS CostPrice
			,p.RetailerPrice AS [RetailerPrice]
			,ofr.OfferId
			,o.OfferCode AS OfferCode
			,CAST(ROUND(ISNULL(p.RetailerPrice - (p.RetailerPrice * o.OfferPercentage / 100), 0), 2) AS NUMERIC(18, 2)) AS OfferPrice
			--,ISNULL(p.RetailOfferPrice, 0) [OfferPrice]
			,CASE 
				WHEN ofr.OfferId IS NOT NULL
					AND o.StartDate <= CAST(@dt AS DATE)
					AND o.EndDate >= CAST(@dt AS DATE)
					THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
				END AS ExpiredOffer
			,ISNULL(o.OfferPercentage, 0) AS OfferPercentage
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM dbo.Products AS p WITH (NOLOCK)
		INNER JOIN OfferProductMapping ofr ON ofr.ProductId = p.ProductId
		INNER JOIN Offers o ON o.OfferId = ofr.OfferId
		WHERE p.TenantId = @TenantId
			AND (
				@OfferId IS NULL
				OR o.OfferId = @OfferId
				)
			AND p.Status <> 3
			AND o.IsDeleted = 0
		ORDER BY CASE 
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
				WHEN @SortBy = 'OfferPrice'
					AND @SortOrder = 'ASC'
					THEN ISNULL(p.RetailOfferPrice, 0)
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferPrice'
					AND @SortOrder = 'DESC'
					THEN ISNULL(p.RetailOfferPrice, 0)
				END DESC
			,CASE 
				WHEN @SortBy = 'RetailerPrice'
					AND @SortOrder = 'ASC'
					THEN p.RetailerPrice
				END ASC
			,CASE 
				WHEN @SortBy = 'RetailerPrice'
					AND @SortOrder = 'DESC'
					THEN RetailerPrice
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)

		SET @ObjectName = OBJECT_NAME(@@PROCID)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage
	END CATCH
END

GO

