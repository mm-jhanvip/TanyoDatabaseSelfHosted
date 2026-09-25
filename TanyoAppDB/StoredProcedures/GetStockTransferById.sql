/*
EXEC dbo.GetStockTransferById 
	@TenantId = 2, 
	@StockTransferId = 1
*/
CREATE   PROCEDURE [dbo].[GetStockTransferById] @TenantId INT
	,@StockTransferId INT
	,@ReturnMessage NVARCHAR(255) = '' OUTPUT
	--,@PageNumber INT = 1
	--,@PageSize INT = 25
	--,@SortBy VARCHAR(50) = 'ProductTitle'
	--,@SortOrder VARCHAR(4) = 'ASC'
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @StockTransferId IS NULL
			OR @StockTransferId <= 0
		BEGIN
			SET @ReturnMessage = 'Invalid StockTransferId supplied.';
			RETURN;
		END

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.StockTransfer WITH (NOLOCK)
				WHERE StockTransferId = @StockTransferId
					AND TenantId = @TenantId
					AND IsDeleted = 0
				)
		BEGIN
			SET @ReturnMessage = CONCAT('Stock transfer with Id',  @StockTransferId, 'was not found.');
			RETURN;
		END

		SELECT 
			-- Below detail for stock transfer
			st.StockTransferId
			,st.StockTransferNo
			,st.StockTransferStatus
			,st.Remarks
			,st.FromWarehouseId
			,fw.Name AS FromWarehouseName
			,st.ToWarehouseId
			,tw.Name AS ToWarehouseName
			,st.CreatedDate
			,st.CreatedBy
			,LTRIM(RTRIM(ISNULL(AN.FirstName, '') + ' ' + ISNULL(AN.LastName, ''))) AS CreatedByUserName
			,st.ReceivedBy
			,LTRIM(RTRIM(ISNULL(RB.FirstName, '') + ' ' + ISNULL(RB.LastName, ''))) AS ReceivedByUserName
			,st.TransferDate

			-- Below detail for stock transfer details
			,std.StockTransferDetailId
			,std.TransferQuantity
			,std.ReceivedQuantity
			,std.ProductId
			,p.ProductTitle
			,p.ModelNo
			,p.CoverImage AS ProductImage			
			,CAST(
				CASE 
					WHEN c.CategoryTypeId = 2 THEN 1
					ELSE 0
				END AS BIT
			) AS IsFabric

			-- Below detail for stock transfer details count
			,SUM(std.TransferQuantity) OVER (PARTITION BY st.StockTransferId) AS TotalTransferQuantity
			,SUM(std.ReceivedQuantity) OVER (PARTITION BY st.StockTransferId) AS TotalReceivedQuantity
			,COUNT(std.StockTransferDetailId) OVER (PARTITION BY st.StockTransferId) AS TotalProducts

			--,COUNT(*) OVER () AS TotalCount
		FROM dbo.StockTransfer st WITH (NOLOCK)
		INNER JOIN dbo.StockTransferDetail std WITH (NOLOCK) ON std.StockTransferId = st.StockTransferId
			AND std.IsDeleted = 0
		INNER JOIN dbo.Warehouse fw WITH (NOLOCK) ON fw.Id = st.FromWarehouseId
		INNER JOIN dbo.Warehouse tw WITH (NOLOCK) ON tw.Id = st.ToWarehouseId
		INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductId = std.ProductId
		INNER JOIN dbo.Categories c WITH (NOLOCK) ON p.CategoryId = c.CategoryId
		INNER JOIN AspNetUsers AS AN WITH (NOLOCK) ON st.CreatedBy = AN.UserId
		LEFT JOIN AspNetUsers AS RB WITH (NOLOCK) ON st.ReceivedBy = RB.UserId
		WHERE st.StockTransferId = @StockTransferId
			AND st.TenantId = @TenantId
			AND st.IsDeleted = 0
		ORDER BY std.StockTransferDetailId ASC
		--CASE 
		--		WHEN @SortBy = 'ProductTitle'
		--			AND @SortOrder = 'ASC'
		--			THEN p.ProductTitle
		--		END ASC
		--	,CASE 
		--		WHEN @SortBy = 'ProductTitle'
		--			AND @SortOrder = 'DESC'
		--			THEN p.ProductTitle
		--		END DESC
		--	,CASE 
		--		WHEN @SortBy = 'TransferQuantity'
		--			AND @SortOrder = 'ASC'
		--			THEN std.TransferQuantity
		--		END ASC
		--	,CASE 
		--		WHEN @SortBy = 'TransferQuantity'
		--			AND @SortOrder = 'DESC'
		--			THEN std.TransferQuantity
		--		END DESC
		--OFFSET(@PageNumber - 1) * @PageSize ROWS

		--FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		DECLARE @ObjectName VARCHAR(500) = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage


		RAISERROR (
				'%s'
				,@ErrorSeverity
				,@ErrorState
				,@ErrorMessage
				);
	END CATCH
END

GO

