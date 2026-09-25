--- =============================================        
--Author  : MagnusMinds -- Create date : 25-09-2024      
--Description : ReportSalesByInterior    
-- =============================================    
/*    
 EXEC ReportSalesByInterior    
   @TenantId = 2    
  ,@InteriorName = ''    
  ,@InteriorNumber = ''    
  ,@PageSize = 50    
  ,@PageIndex = 1    
  ,@SortBy = 'NoOfOrders'    
  ,@SortOrder = 'DESC'    
*/
CREATE PROC [dbo].[zReportSalesByInterior_Backup_20240927] (
	@TenantId INT
	,@InteriorName VARCHAR(50) = NULL
	,@InteriorNumber VARCHAR(50) = NULL
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@SortBy VARCHAR(50) = 'NoOfOrders'
	,@SortOrder VARCHAR(50) = 'DESC'
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		WITH cte
		AS (
			SELECT C.CustomerId AS InteriorId
				,(C.FirstName + ' ' + C.LastName) AS InteriorName
				,C.PhoneNumber AS InteriorNumber
				,ISNULL(cv.NoOfVisits, 0) AS NoOfVisits
				,ISNULL(o.NoOfOpenInquiries, 0) AS NoOfOpenInquiries
				,ISNULL(o.NoOfOrders, 0) AS NoOfOrders
				,CAST(ISNULL(ROUND(o.AmountOfOrders, 0), 0) AS DECIMAL) AS AmountOfOrders
			FROM Customers C WITH (NOLOCK)
			INNER JOIN (
				SELECT c.RefferedBy AS CustomerID
					,SUM(CASE 
							WHEN O.STATUS IN (0)
								THEN 1
							ELSE 0
							END) AS NoOfOpenInquiries -- Inquiry = 0  
					,SUM(CASE 
							WHEN O.STATUS IN (2, 3, 4, 5)
								THEN 1
							ELSE 0
							END) AS NoOfOrders -- Approved = 2  
					,SUM(CASE 
							WHEN O.STATUS IN (2, 3, 4, 5)
								THEN o.AmountBeforeGST + o.CGSTAmount + o.SGSTAmount
							ELSE 0
							END) AS AmountOfOrders
				FROM Orders o WITH (NOLOCK)
				INNER JOIN Customers c WITH (NOLOCK) ON c.CustomerId = o.CustomerID
				INNER JOIN AspNetUsers a WITH (NOLOCK) ON A.UserId = o.CreatedBy
				WHERE o.TenantId = @TenantId
					AND a.IsDeleted = 0
					AND c.RefferedBy > 0
					AND o.STATUS NOT IN (6, 9)
					AND (
						@FromDate IS NULL
						OR CONVERT(DATE, o.CreatedDate) >= @FromDate
						)
					AND (
						@ToDate IS NULL
						OR CONVERT(DATE, o.CreatedDate) <= @ToDate
						)
				GROUP BY c.RefferedBy
				) o ON o.CustomerId = C.CustomerId
			LEFT JOIN (
				SELECT c.CustomerId
					,COUNT(1) AS NoOfVisits
				FROM CustomerVisits cv WITH (NOLOCK)
				INNER JOIN Customers c WITH (NOLOCK) ON c.CustomerId = cv.CustomerID
					AND c.RefferedBy > 0
				GROUP BY c.CustomerId
				) cv ON cv.CustomerId = C.CustomerId
			WHERE C.CustomerTypeID = 2 --only interior  
				AND C.IsDeleted = 0
				AND C.TenantID = @TenantId
				AND (
					ISNULL(@InteriorName, '') = ''
					OR (C.FirstName + ' ' + C.LastName) LIKE '%' + @InteriorName + '%'
					)
				AND (
					ISNULL(@InteriorNumber, '') = ''
					OR (C.PhoneNumber) LIKE '%' + @InteriorNumber + '%'
					)
				AND (
					o.NoOfOrders > 0
					OR o.NoOfOpenInquiries > 0
					)
			)
		SELECT *
			,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM cte
		ORDER BY CASE 
				WHEN @SortBy = 'InteriorName'
					AND @SortOrder = 'ASC'
					THEN InteriorName
				END
			,CASE 
				WHEN @SortBy = 'InteriorName'
					AND @SortOrder = 'DESC'
					THEN InteriorName
				END DESC
			,CASE 
				WHEN @SortBy = 'InteriorNumber'
					AND @SortOrder = 'ASC'
					THEN InteriorNumber
				END
			,CASE 
				WHEN @SortBy = 'InteriorNumber'
					AND @SortOrder = 'DESC'
					THEN InteriorNumber
				END DESC
			,CASE 
				WHEN @SortBy = 'NoOfVisits'
					AND @SortOrder = 'ASC'
					THEN NoOfVisits
				END
			,CASE 
				WHEN @SortBy = 'NoOfVisits'
					AND @SortOrder = 'DESC'
					THEN NoOfVisits
				END DESC
			,CASE 
				WHEN @SortBy = 'NoOfOpenInquiries'
					AND @SortOrder = 'ASC'
					THEN NoOfOpenInquiries
				END
			,CASE 
				WHEN @SortBy = 'NoOfOpenInquiries'
					AND @SortOrder = 'DESC'
					THEN NoOfOpenInquiries
				END DESC
			,CASE 
				WHEN @SortBy = 'NoOfOrders'
					AND @SortOrder = 'ASC'
					THEN NoOfOrders
				END
			,CASE 
				WHEN @SortBy = 'NoOfOrders'
					AND @SortOrder = 'DESC'
					THEN NoOfOrders
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

