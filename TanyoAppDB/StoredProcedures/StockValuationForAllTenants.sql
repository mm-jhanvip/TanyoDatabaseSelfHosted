CREATE PROCEDURE [dbo].[StockValuationForAllTenants]
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		DROP TABLE IF EXISTS #Tenants

		DROP TABLE IF EXISTS #StockValuationReport

		DECLARE @Count INT = 0
				,@Inc INT = 1
				,@TenantId INT

		SELECT *
			,ROW_NUMBER() OVER (
				ORDER BY TenantId
				) AS Id
		INTO #Tenants
		FROM Tenants
		WHERE ISDELETED = 0
		ORDER BY TenantId

		SELECT @Count = COUNT(Id)
		FROM #Tenants

		WHILE @Inc <= @Count
		BEGIN
			SELECT @TenantId = TenantId
			FROM #Tenants
			WHERE Id = @Inc

			DROP TABLE IF EXISTS #StockValuationReport

				CREATE TABLE #StockValuationReport (
					ProductId BIGINT
					,ImagePath VARCHAR(MAX)
					,ProductTitle VARCHAR(150)
					,ActualStock NUMERIC(18, 2) NULL
					,CategoryName VARCHAR(150)
					,CategoryId BIGINT
					,ModelNo VARCHAR(100)
					,TotalCount INT
					,ValuationOfActualStock NUMERIC(18, 2)
					,ValuationOfRetailStock NUMERIC(18, 2)
					,ValuationOfWholesaleStock NUMERIC(18, 2)
					,GrandTotalActualStock NUMERIC(18, 2)
					,GrandTotalValuationOfActualStock NUMERIC(18, 2)
					,GrandTotalValuationOfRetailStock NUMERIC(18, 2)
					,GrandTotalValuationOfWholesaleStock NUMERIC(18, 2)
					,TotalActualStock NUMERIC(18, 2)
					,TotalValuationOfActualStock NUMERIC(18, 2)
					,TotalValuationOfRetailStock NUMERIC(18, 2)
					,TotalValuationOfWholesaleStock NUMERIC(18, 2)
					)

			INSERT INTO #StockValuationReport
			EXEC [dbo].[StockValuationReport] @TenantId = @TenantId
				,@ProductTitle = NULL
				,@ModelNo = NULL
				,@CategoryId = NULL
				,@PageIndex = '1'
				,@PageSize = '1000000000'

			INSERT INTO DailyStockValuation (
				ProductId
				,ImagePath
				,ProductTitle
				,ActualStock
				,CategoryName
				,CategoryId
				,ModelNo
				,ValuationOfActualStock
				,ValuationOfRetailStock
				,ValuationOfWholesaleStock
				)
			SELECT ProductId
				,ImagePath
				,ProductTitle
				,ActualStock
				,CategoryName
				,CategoryId
				,ModelNo
				,ValuationOfActualStock
				,ValuationOfRetailStock
				,ValuationOfWholesaleStock
			FROM #StockValuationReport

			SET @Inc = @Inc + 1
		END
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

