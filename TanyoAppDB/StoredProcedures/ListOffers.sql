/*
EXEC [dbo].[ListOffers]
    @TenantId = 2
    ,@OfferCode       = NULL
    ,@OfferTitle      = NULL
    ,@OfferPercentage = NULL
    ,@PublishStatus   = NULL
    ,@OfferTypeId     = NULL
    ,@SortBy          = NULL
    ,@SortOrder       = NULL
    ,@PageNumber      = 1
    ,@PageSize        = 200
*/
CREATE PROCEDURE [dbo].[ListOffers] (
	@TenantId INT
	,@OfferCode NVARCHAR(100) = NULL
	,@OfferTitle NVARCHAR(200) = NULL
	,@OfferPercentage INT = NULL
	,@PublishStatus INT = NULL --  0 = Unpublished, 1 = Published
	,@OfferTypeId INT = NULL
	,@SortBy NVARCHAR(100) = 'UpdatedDate'
	,@SortOrder NVARCHAR(4) = 'DESC'
	,@PageNumber INT = 1
	,@PageSize INT = 100
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @Today DATE = CAST(GETDATE() AS DATE);
			-- CTE: Product count per offer only
			;

		WITH ProductCountCTE
		AS (
			SELECT OPM.OfferId
				,COUNT(OPM.ProductId) AS ProductCount
			FROM OfferProductMapping OPM WITH (NOLOCK)
			INNER JOIN Products P WITH (NOLOCK) ON P.ProductId = OPM.ProductId
			GROUP BY OPM.OfferId
			)
		SELECT O.OfferId
			,O.OfferCode
			,O.OfferTitle
			,ISNULL(O.OfferDescription, '') AS OfferDescription
			,O.OfferTypeId
			,O.StartDate
			,O.EndDate
			,O.OfferPercentage
			,O.IsPublished
			,ISNULL(O.UpdatedBy, O.CreatedBy) AS UpdatedBy
			,CASE 
				WHEN O.UpdatedBy IS NOT NULL
					THEN UU.FirstName + ' ' + UU.LastName
				ELSE CU.FirstName + ' ' + CU.LastName
				END AS UpdatedByName
			,ISNULL(O.UpdatedDate, O.CreatedDate) AS UpdatedDate
			,CASE 
				WHEN CAST(O.EndDate AS DATE) < @Today
					THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
				END AS IsExpired
			,ISNULL(PC.ProductCount, 0) AS [ProductCounts]
			,COUNT(1) OVER () AS TotalCount
		FROM Offers O WITH (NOLOCK)
		INNER JOIN AspNetUsers CU WITH (NOLOCK) ON CU.UserId = O.CreatedBy
		LEFT JOIN AspNetUsers UU WITH (NOLOCK) ON UU.UserId = O.UpdatedBy
		LEFT JOIN ProductCountCTE PC WITH (NOLOCK) ON PC.OfferId = O.OfferId
		WHERE (
				@OfferCode IS NULL
				OR O.OfferCode LIKE '%' + @OfferCode + '%'
				)
			AND (
				@OfferTitle IS NULL
				OR O.OfferTitle LIKE '%' + @OfferTitle + '%'
				)
			AND (
				@OfferPercentage IS NULL
				OR CONVERT(VARCHAR(20), O.OfferPercentage) LIKE '%' + CONVERT(VARCHAR(20), @OfferPercentage) + '%'
				)
			--AND (@OfferPercentage IS NULL OR O.OfferPercentage = @OfferPercentage)
			AND (
				@OfferTypeId IS NULL
				OR O.OfferTypeId = @OfferTypeId
				)
			AND (
				@PublishStatus IS NULL
				OR O.IsPublished = @PublishStatus
				)
			AND (O.TenantId = @TenantId)
			AND O.IsDeleted = 0
		ORDER BY
			-- OfferId
			CASE 
				WHEN @SortBy = 'OfferId'
					AND @SortOrder = 'ASC'
					THEN O.OfferId
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferId'
					AND @SortOrder = 'DESC'
					THEN O.OfferId
				END DESC
			,
			-- OfferCode
			CASE 
				WHEN @SortBy = 'OfferCode'
					AND @SortOrder = 'ASC'
					THEN O.OfferCode
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferCode'
					AND @SortOrder = 'DESC'
					THEN O.OfferCode
				END DESC
			,
			-- OfferTitle
			CASE 
				WHEN @SortBy = 'OfferTitle'
					AND @SortOrder = 'ASC'
					THEN O.OfferTitle
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferTitle'
					AND @SortOrder = 'DESC'
					THEN O.OfferTitle
				END DESC
			,
			-- OfferPercentage
			CASE 
				WHEN @SortBy = 'OfferPercentage'
					AND @SortOrder = 'ASC'
					THEN O.OfferPercentage
				END ASC
			,CASE 
				WHEN @SortBy = 'OfferPercentage'
					AND @SortOrder = 'DESC'
					THEN O.OfferPercentage
				END DESC
			,
			-- StartDate
			CASE 
				WHEN @SortBy = 'StartDate'
					AND @SortOrder = 'ASC'
					THEN O.StartDate
				END ASC
			,CASE 
				WHEN @SortBy = 'StartDate'
					AND @SortOrder = 'DESC'
					THEN O.StartDate
				END DESC
			,
			-- EndDate
			CASE 
				WHEN @SortBy = 'EndDate'
					AND @SortOrder = 'ASC'
					THEN O.EndDate
				END ASC
			,CASE 
				WHEN @SortBy = 'EndDate'
					AND @SortOrder = 'DESC'
					THEN O.EndDate
				END DESC
			,
			-- UpdatedByName
			CASE 
				WHEN @SortBy = 'UpdatedByName'
					AND @SortOrder = 'ASC'
					THEN CASE 
							WHEN O.UpdatedBy IS NOT NULL
								THEN UU.FirstName + ' ' + UU.LastName
							ELSE CU.FirstName + ' ' + CU.LastName
							END
				END ASC
			,CASE 
				WHEN @SortBy = 'UpdatedByName'
					AND @SortOrder = 'DESC'
					THEN CASE 
							WHEN O.UpdatedBy IS NOT NULL
								THEN UU.FirstName + ' ' + UU.LastName
							ELSE CU.FirstName + ' ' + CU.LastName
							END
				END DESC
			,
			-- UpdatedDate
			CASE 
				WHEN @SortBy = 'UpdatedDate'
					AND @SortOrder = 'ASC'
					THEN ISNULL(O.UpdatedDate, O.CreatedDate)
				END ASC
			,CASE 
				WHEN @SortBy = 'UpdatedDate'
					AND @SortOrder = 'DESC'
					THEN ISNULL(O.UpdatedDate, O.CreatedDate)
				END DESC
			,
			-- Product Count
			CASE 
				WHEN @SortBy = 'ProductCount'
					AND @SortOrder = 'ASC'
					THEN ISNULL(PC.ProductCount, 0)
				END ASC
			,CASE 
				WHEN @SortBy = 'ProductCount'
					AND @SortOrder = 'DESC'
					THEN ISNULL(PC.ProductCount, 0)
				END DESC
			,
			-- Default fallback
			O.UpdatedDate DESC 
			
		OFFSET(@PageNumber - 1) * @PageSize ROWS
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
END;

GO

