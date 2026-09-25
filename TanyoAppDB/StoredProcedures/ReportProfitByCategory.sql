/*  
EXEC ReportProfitByCategory  
@TenantId = 2  
,@FromDate = '2026-01-01'  
,@ToDate =  '2026-04-14'  
*/
CREATE PROCEDURE [dbo].[ReportProfitByCategory] (
	@TenantId INT
	,@FromDate DATE
	,@ToDate DATE
	,@CategoryIds VARCHAR(MAX) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@SortBy VARCHAR(50) = 'CategoryName'
	,@SortOrder VARCHAR(50) = 'ASC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @IsBeforeGSTFlag BIT = 0
			,@FromDateTime DATETIMEOFFSET = NULL
			,@ToDateTime DATETIMEOFFSET = NULL;

		SELECT @FromDateTime = CAST(@FromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30'
			,@ToDateTime = CAST(@ToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30'

		SELECT @IsBeforeGSTFlag = IsBeforeGST
		FROM Tenants
		WHERE TenantId = @TenantId

		CREATE TABLE #FilteredCategories (CategoryId BIGINT);

		IF (
				@CategoryIds IS NOT NULL
				AND LEN(LTRIM(RTRIM(@CategoryIds))) > 0
				)
		BEGIN
			INSERT INTO #FilteredCategories (CategoryId)
			SELECT CAST(value AS BIGINT)
			FROM STRING_SPLIT(@CategoryIds, ',')
			WHERE LTRIM(RTRIM(value)) != '';
		END

		IF (@IsBeforeGSTFlag = 1)
		BEGIN
				;

			WITH ProfitsByCategory
			AS (
				SELECT CT.CategoryName
					,CT.CategoryId
					,ISNULL(CAST(SUM(osi.InstantCostPrice * osi.Quantity) AS INT), 0) AS TotalCostPriceByOrder
					,ISNULL(CAST(SUM(osi.AmountBeforeGST) AS INT), 0) AS InvoiceAmt
					,ISNULL((- 1) * CAST(SUM(ROUND(osi.SalesmanCommission, 0)) AS INT), 0) AS SalesmanCommission
					,ISNULL((- 1) * CAST(SUM(ROUND(osi.InteriorCommission, 0)) AS INT), 0) AS InteriorCommission
					,CAST(SUM(ISNULL(osi.AmountBeforeGST, 0) - ISNULL(osi.InteriorCommission, 0) - ISNULL(osi.SalesmanCommission, 0) - ISNULL(osi.InstantCostPrice * osi.Quantity, 0)) AS INT) AS TotalProfit
					,ISNULL(ROUND(((CAST(SUM(ISNULL(osi.AmountBeforeGST, 0) - ISNULL(osi.InteriorCommission, 0) - ISNULL(osi.SalesmanCommission, 0) - ISNULL(osi.InstantCostPrice * osi.Quantity, 0)) AS NUMERIC(18, 2))) / NULLIF(CAST(SUM(osi.AmountBeforeGST) AS NUMERIC(18, 2)), 0)) * 100, 2), 0) AS ProfitPercentage
					,COUNT(1) OVER () AS TotalCount
				FROM [dbo].[Orders] AS o WITH (NOLOCK)
				INNER JOIN [dbo].[OrderSetItems] AS osi ON osi.OrderId = o.OrderId
					AND osi.IsDeleted = 0
				INNER JOIN Products PT ON PT.ProductId = OSI.SubjectId
				INNER JOIN Categories CT ON PT.CategoryId = CT.CategoryId
					AND CT.IsDeleted = 0
					AND CT.TenantId = @TenantId
				WHERE o.TenantId = @TenantId
					AND o.Status IN (
						2
						,3
						,4
						,5
						)
					AND o.ApprovedDate >= @FromDateTime
					AND o.ApprovedDate <= @ToDateTime
					AND (
						NOT EXISTS (
							SELECT 1
							FROM #FilteredCategories
							) -- No filter = show all  
						OR CT.CategoryId IN (
							SELECT CategoryId
							FROM #FilteredCategories
							)
						)
				GROUP BY CT.CategoryName
					,CT.CategoryId
				)
			SELECT CategoryName
				,CategoryId
				,InvoiceAmt AS TotalSalesAmount
				,SalesmanCommission
				,InteriorCommission
				,TotalProfit
				,TotalCostPriceByOrder AS TotalCostAmount
				,ProfitPercentage
				,TotalCount
				,SUM(InvoiceAmt) OVER () AS GrandTotalSalesAmount
				,SUM(TotalCostPriceByOrder) OVER () AS GrandTotalCostAmount
				,SUM(SalesmanCommission) OVER () AS GrandSalesmanCommission
				,SUM(InteriorCommission) OVER () AS GrandInteriorCommission
				,SUM(TotalProfit) OVER () AS GrandTotalProfit
				,SUM(ProfitPercentage) OVER () AS GrandProfitPercentage
			FROM ProfitsByCategory
			ORDER BY CASE 
					WHEN @SortBy = 'TotalCostAmount'
						AND @SortOrder = 'ASC'
						THEN TotalCostPriceByOrder
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalCostAmount'
						AND @SortOrder = 'DESC'
						THEN TotalCostPriceByOrder
					END DESC
				,CASE 
					WHEN @SortBy = 'TotalSalesAmount'
						AND @SortOrder = 'ASC'
						THEN InvoiceAmt
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalSalesAmount'
						AND @SortOrder = 'DESC'
						THEN InvoiceAmt
					END DESC
				,CASE 
					WHEN @SortBy = 'SalesmanCommission'
						AND @SortOrder = 'ASC'
						THEN SalesmanCommission
					END ASC
				,CASE 
					WHEN @SortBy = 'SalesmanCommission'
						AND @SortOrder = 'DESC'
						THEN SalesmanCommission
					END DESC
				,CASE 
					WHEN @SortBy = 'InteriorCommission'
						AND @SortOrder = 'ASC'
						THEN InteriorCommission
					END ASC
				,CASE 
					WHEN @SortBy = 'InteriorCommission'
						AND @SortOrder = 'DESC'
						THEN InteriorCommission
					END DESC
				,CASE 
					WHEN @SortBy = 'TotalProfit'
						AND @SortOrder = 'ASC'
						THEN TotalProfit
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalProfit'
						AND @SortOrder = 'DESC'
						THEN TotalProfit
					END DESC
				,CASE 
					WHEN @SortBy = 'ProfitPercentage'
						AND @SortOrder = 'ASC'
						THEN ProfitPercentage
					END ASC
				,CASE 
					WHEN @SortBy = 'ProfitPercentage'
						AND @SortOrder = 'DESC'
						THEN ProfitPercentage
					END DESC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'ASC'
						THEN CategoryName
					END ASC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'DESC'
						THEN CategoryName
					END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
				;

			WITH ProfitsByCategory
			AS (
				SELECT CT.CategoryName
					,CT.CategoryId
					,ISNULL(CAST(SUM(osi.InstantCostPrice * osi.Quantity) AS INT), 0) AS TotalCostPriceByOrder
					,ISNULL(CAST(SUM(osi.TotalAmount) AS INT), 0) AS InvoiceAmt
					,ISNULL((- 1) * CAST(SUM(osi.SalesmanCommission) AS INT), 0) AS SalesmanCommission
					,ISNULL((- 1) * CAST(SUM(osi.InteriorCommission) AS INT), 0) AS InteriorCommission
					,CAST(SUM(ISNULL(osi.TotalAmount, 0) - ISNULL(osi.InteriorCommission, 0) - ISNULL(osi.SalesmanCommission, 0) - ISNULL(osi.InstantCostPrice * osi.Quantity, 0)) AS INT) AS TotalProfit
					,ISNULL(ROUND(((CAST(SUM(ISNULL(osi.TotalAmount, 0) - ISNULL(osi.InteriorCommission, 0) - ISNULL(osi.SalesmanCommission, 0) - ISNULL(osi.InstantCostPrice * osi.Quantity, 0)) AS NUMERIC(18, 2))) / NULLIF(CAST(SUM(osi.TotalAmount) AS NUMERIC(18, 2)), 0)) * 100, 2), 0) AS ProfitPercentage
					,COUNT(1) OVER () AS TotalCount
				FROM [dbo].[Orders] AS o WITH (NOLOCK)
				INNER JOIN [dbo].[OrderSetItems] AS osi ON osi.OrderId = o.OrderId
					AND osi.IsDeleted = 0
				INNER JOIN Products PT ON PT.ProductId = OSI.SubjectId
				INNER JOIN Categories CT ON PT.CategoryId = CT.CategoryId
					AND CT.IsDeleted = 0
					AND CT.TenantId = @TenantId
				WHERE o.TenantId = @TenantId
					AND o.Status IN (
						2
						,3
						,4
						,5
						)
					AND o.ApprovedDate >= @FromDateTime
					AND o.ApprovedDate <= @ToDateTime
					AND (
						NOT EXISTS (
							SELECT 1
							FROM #FilteredCategories
							) -- No filter = show all  
						OR CT.CategoryId IN (
							SELECT CategoryId
							FROM #FilteredCategories
							)
						)
				GROUP BY CT.CategoryName
					,CT.CategoryId
				)
			SELECT CategoryName
				,CategoryId
				,InvoiceAmt AS TotalSalesAmount
				,SalesmanCommission
				,InteriorCommission
				,TotalProfit
				,TotalCostPriceByOrder AS TotalCostAmount
				,ProfitPercentage
				,TotalCount
				,SUM(InvoiceAmt) OVER () AS GrandTotalSalesAmount
				,SUM(TotalCostPriceByOrder) OVER () AS GrandTotalCostAmount
				,SUM(SalesmanCommission) OVER () AS GrandSalesmanCommission
				,SUM(InteriorCommission) OVER () AS GrandInteriorCommission
				,SUM(TotalProfit) OVER () AS GrandTotalProfit
				,SUM(ProfitPercentage) OVER () AS GrandProfitPercentage
			FROM ProfitsByCategory
			ORDER BY CASE 
					WHEN @SortBy = 'TotalCostAmount'
						AND @SortOrder = 'ASC'
						THEN TotalCostPriceByOrder
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalCostAmount'
						AND @SortOrder = 'DESC'
						THEN TotalCostPriceByOrder
					END DESC
				,CASE 
					WHEN @SortBy = 'TotalSalesAmount'
						AND @SortOrder = 'ASC'
						THEN InvoiceAmt
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalSalesAmount'
						AND @SortOrder = 'DESC'
						THEN InvoiceAmt
					END DESC
				,CASE 
					WHEN @SortBy = 'SalesmanCommission'
						AND @SortOrder = 'ASC'
						THEN SalesmanCommission
					END ASC
				,CASE 
					WHEN @SortBy = 'SalesmanCommission'
						AND @SortOrder = 'DESC'
						THEN SalesmanCommission
					END DESC
				,CASE 
					WHEN @SortBy = 'InteriorCommission'
						AND @SortOrder = 'ASC'
						THEN InteriorCommission
					END ASC
				,CASE 
					WHEN @SortBy = 'InteriorCommission'
						AND @SortOrder = 'DESC'
						THEN InteriorCommission
					END DESC
				,CASE 
					WHEN @SortBy = 'TotalProfit'
						AND @SortOrder = 'ASC'
						THEN TotalProfit
					END ASC
				,CASE 
					WHEN @SortBy = 'TotalProfit'
						AND @SortOrder = 'DESC'
						THEN TotalProfit
					END DESC
				,CASE 
					WHEN @SortBy = 'ProfitPercentage'
						AND @SortOrder = 'ASC'
						THEN ProfitPercentage
					END ASC
				,CASE 
					WHEN @SortBy = 'ProfitPercentage'
						AND @SortOrder = 'DESC'
						THEN ProfitPercentage
					END DESC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'ASC'
						THEN CategoryName
					END ASC
				,CASE 
					WHEN @SortBy = 'CategoryName'
						AND @SortOrder = 'DESC'
						THEN CategoryName
					END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

			FETCH NEXT @PageSize ROWS ONLY
		END

		DROP TABLE #FilteredCategories
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

