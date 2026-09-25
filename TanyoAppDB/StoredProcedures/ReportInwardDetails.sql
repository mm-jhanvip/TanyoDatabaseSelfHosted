/*
 EXEC [ReportInwardDetails]
	 @TenantId = 2
	,@InwardFromDate = '2026-01-01'
	,@InwardToDate = '2026-07-30'
	,@VendorId = NULL
	,@ProductSearch = null
	,@PageIndex = 1
	,@PageSize = 50
	,@SortBy = 'CreatedDate'
	,@SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[ReportInwardDetails] (
	 @TenantId INT
	,@InwardFromDate DATE
	,@InwardToDate DATE
	,@VendorId BIGINT = NULL
	,@ProductSearch VARCHAR(100) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = ''
	,@SortOrder VARCHAR(50) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT p.ProductTitle + ' - ' +  p.ModelNo AS ProductTitle
			,IE.CreatedDate AS CreatedDate
			,IDE.Quantity AS Quantity
			,IDE.Amount AS Amount
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM InwardEntry IE WITH (NOLOCK)
		INNER JOIN InwardDetailsEntry IDE WITH (NOLOCK) ON IE.InwardId = IDE.InwardId
		LEFT JOIN Products P WITH (NOLOCK) ON P.ProductId = IDE.ProductId
			AND p.TenantId = @TenantId
		WHERE IDE.IsDeleted = 0
		AND IE.IsDeleted = 0
		AND IE.TenantId = @TenantId
		AND (@ProductSearch IS NULL OR (p.ProductTitle + ' - ' + p.ModelNo) LIKE '%' + @ProductSearch + '%')
		AND (@VendorId IS NULL OR IE.VendorId = @VendorId)
		AND IE.CreatedDate >= @InwardFromDate
		AND IE.CreatedDate <= @InwardToDate
		ORDER BY CASE 
			WHEN @SortBy = 'ProductTitle'
				AND @SortOrder = 'ASC'
				THEN P.ProductTitle
			END ASC
		,CASE 
			WHEN @SortBy = 'ProductTitle'
				AND @SortOrder = 'DESC'
				THEN P.ProductTitle
			END DESC
		,CASE 
			WHEN @SortBy = 'Quantity'
				AND @SortOrder = 'ASC'
				THEN IDE.Quantity
			END ASC
		,CASE 
			WHEN @SortBy = 'Quantity'
				AND @SortOrder = 'DESC'
				THEN IDE.Quantity
			END DESC
		,CASE 
			WHEN @SortBy = 'Amount'
				AND @SortOrder = 'ASC'
				THEN IDE.Amount
			END ASC
		,CASE 
			WHEN @SortBy = 'Amount'
				AND @SortOrder = 'DESC'
				THEN IDE.Amount
		END DESC
		,CASE 
			WHEN @SortBy = 'CreatedDate'
				AND @SortOrder = 'ASC'
				THEN IDE.CreatedDate
			END ASC
		,CASE 
			WHEN @SortBy = 'CreatedDate'
				AND @SortOrder = 'DESC'
				THEN IDE.CreatedDate
		END DESC 
		OFFSET(@PageIndex - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;

	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()
			,@ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage
		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

