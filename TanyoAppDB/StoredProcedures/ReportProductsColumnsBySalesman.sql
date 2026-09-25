/*
	EXEC [dbo].[ReportProductsColumnsBySalesman] 
		@TenantId = 1207
		,@FromDate = '2026-08-01'
		,@ToDate = '2026-08-31'
		,@SalesmanId = -1
*/
CREATE PROCEDURE [dbo].[ReportProductsColumnsBySalesman] (
	@TenantId INT
	,@FromDate DATE
	,@ToDate DATE
	,@SalesmanId BIGINT = - 1
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @ApproveFromDateTime DATETIMEOFFSET(7) = CAST(@FromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30'
			,@ApproveToDateTime DATETIMEOFFSET(7) = CAST(@ToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30';

		IF OBJECT_ID('tempdb..#orderItems') IS NOT NULL 
			DROP TABLE #orderItems;

		DECLARE @DynamicColumns NVARCHAR(MAX);
		DECLARE @DynamicQuery NVARCHAR(MAX);

		SELECT CAST(O.CreatedDate AS DATE) AS OrderDate
			,aus.FirstName + ' ' + aus.LastName AS SalesmanName
			,O.OrderNo
			,C.CategoryName
			,P.ProductTitle
			,OD.TotalAmount * OD.Quantity AS Amount 
		INTO #orderItems
		FROM Orders O WITH (NOLOCK)
		INNER JOIN AspNetUsers aus WITH (NOLOCK) ON O.SalesmanId = aus.UserId
		INNER JOIN OrderSetItems OD WITH (NOLOCK) ON O.OrderId = OD.OrderId
		INNER JOIN Products P WITH (NOLOCK) ON OD.SubjectId = P.ProductId
		LEFT JOIN Categories C WITH (NOLOCK) ON P.CategoryId = C.CategoryId
		WHERE O.TenantId = @TenantId
			AND O.ApprovedDate >= @ApproveFromDateTime
			AND O.ApprovedDate <= @ApproveToDateTime
			AND P.ProductId IS NOT NULL
			AND (
				@SalesmanId = - 1 
				OR aus.UserId = @SalesmanId
				);

		SELECT @DynamicColumns = STRING_AGG(QUOTENAME(CategoryName), ',')
		FROM (
			SELECT DISTINCT CategoryName
			FROM #orderItems
			WHERE CategoryName IS NOT NULL
			) C;

		IF @DynamicColumns IS NOT NULL
		BEGIN
			SET @DynamicQuery = N'
				SELECT
					SalesmanName,
					ProductTitle,
					' + @DynamicColumns + '
				FROM
				(
					SELECT
						SalesmanName,
						ProductTitle,
						CategoryName,
						Amount
					FROM #orderItems
				) AS SourceData
				PIVOT
				(
					SUM(Amount)
					FOR CategoryName IN (' + @DynamicColumns + ')
				) AS P
				ORDER BY
					SalesmanName;
			';

			EXEC sp_executesql @DynamicQuery;
		END
		
		DROP TABLE #orderItems;

	END TRY
	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500) = OBJECT_NAME(@@PROCID),
			    @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();

		IF OBJECT_ID('tempdb..#orderItems') IS NOT NULL 
			DROP TABLE #orderItems;

		EXEC dbo.SaveDBErrorLog 
             @ObjectName = @ObjectName,
			 @ErrorMsg = @ErrorMsg;
             
	END CATCH
END

GO

