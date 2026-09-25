CREATE PROCEDURE [dbo].[ReportSalesManCheckIn] (
	@TenantId BIGINT
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@SalesmanIds VARCHAR(MAX) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 10
	,@SortBy NVARCHAR(50) = 'CheckInTime'
	,@SortOrder NVARCHAR(4) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		SELECT CONCAT (
				TRIM(U.FirstName)
				,' '
				,TRIM(LastName)
				) AS SalesmanName
			,StartDate AS CheckInTime
			,ISNULL(InLatitude, '') AS CheckInLatitude
			,ISNULL(InLongitude, '') AS CheckInLongitude
			,isnull(EndDate, '') AS CheckOutTime
			,ISNULL(OutLatitude, '') AS CheckOutLatitude
			,ISNULL(OutLongitude, '') AS CheckOutLongitude
			,U.UserId AS SalesmanID
			,COUNT(*) OVER () AS TotalCount
		FROM Attendance A WITH (NOLOCK)
		INNER JOIN AspNetUsers U WITH (NOLOCK) ON A.UserId = U.UserId
			AND U.IsDeleted = 0
		INNER JOIN UserTenantMapping UTM WITH (NOLOCK) ON UTM.UserId = U.UserId
			AND UTM.TenantId = @TenantId
		WHERE Type = 0
			AND (
				(
					CAST(A.CreatedDate AS DATE) BETWEEN @FromDate
						AND @ToDate
					)
				OR (
					@FromDate IS NULL
					AND @ToDate IS NULL
					)
				)
			AND (
				@SalesmanIds IS NULL
				OR U.UserId IN (
					SELECT TRIM(value)
					FROM STRING_SPLIT(@SalesmanIds, ',')
					)
				)
		ORDER BY CASE 
				WHEN @SortBy = 'CheckInTime'
					AND @SortOrder = 'ASC'
					THEN StartDate
				END ASC
			,CASE 
				WHEN @SortBy = 'CheckInTime'
					AND @SortOrder = 'DESC'
					THEN StartDate
				END DESC
			,CASE 
				WHEN @SortBy = 'CheckOutTime'
					AND @SortOrder = 'ASC'
					THEN EndDate
				END ASC
			,CASE 
				WHEN @SortBy = 'CheckOutTime'
					AND @SortOrder = 'DESC'
					THEN EndDate
				END DESC
			,CASE 
				WHEN @SortBy = 'SalesmanName'
					AND @SortOrder = 'ASC'
					THEN CONCAT (
							U.FirstName
							,' '
							,LastName
							)
				END ASC
			,CASE 
				WHEN @SortBy = 'SalesmanName'
					AND @SortOrder = 'DESC'
					THEN CONCAT (
							U.FirstName
							,' '
							,LastName
							)
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

