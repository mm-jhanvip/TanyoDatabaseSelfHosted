/* 
EXEC [dbo].[CancelStockTransfer] @TenantId = 1, @StockTransferIds = '1,2', @UserId = 4279
*/
CREATE     PROCEDURE [dbo].[CancelStockTransfer] (
	@TenantId INT
	,@StockTransferIds VARCHAR(MAX)
	,@UserId BIGINT
	,@ReturnMessage NVARCHAR(255) = '' OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Status BIT
		,@Message VARCHAR(100)
		,@ErrorMsg VARCHAR(MAX)
		,@CurrentRow INT
		,@TotalRows INT
		,@CurrentProductId BIGINT
		,@Quantity DECIMAL(18, 2)
		,@WarehouseId INT
		,@OldQuantity DECIMAL(18, 2)
		,@SellableOldQuantity DECIMAL(18, 2)
		,@SellableNewQuantity DECIMAL(18, 2)
		,@NewWarehouseQuantity DECIMAL(18, 2)
		,@Description VARCHAR(500)
		,@StockTransferNumber VARCHAR(20)
		,@FromWarehouseName VARCHAR(100)
		,@Result INT;

	DECLARE @Dt DATETIMEOFFSET = SYSDATETIMEOFFSET();


	BEGIN TRY
		CREATE TABLE #StockTransferIds (StockTransferId BIGINT);

		CREATE TABLE #StockTrasferDetail (
			RowID INT IDENTITY(1, 1)
			,ProductId BIGINT
			,Quantity DECIMAL(18, 2)
			,WareHouseQuantity DECIMAL(18, 2)
			,ProductQuantity DECIMAL(18, 2)
			,WareHouseId INT
			,StockTransferStatus INT
			,StockTransferNumber VARCHAR(20)
			,FromWarehouseName VARCHAR(100)
			);

		INSERT INTO #StockTransferIds (StockTransferId)
		SELECT CAST(TRIM(value) AS BIGINT)
		FROM STRING_SPLIT(TRIM(@StockTransferIds), ',');

		INSERT INTO #StockTrasferDetail (
			ProductId
			,Quantity
			,WareHouseId
			,StockTransferStatus
			,StockTransferNumber
			,FromWarehouseName
			)
		SELECT STD.ProductId
			,STD.TransferQuantity
			,ST.FromWarehouseId
			,ST.StockTransferStatus
			,ST.StockTransferNo
			,W.Name
		FROM dbo.StockTransfer ST
		INNER JOIN dbo.StockTransferDetail STD ON ST.StockTransferId = STD.StockTransferId
		LEFT JOIN Warehouse W ON ST.FromWarehouseId = W.Id
		WHERE STD.StockTransferId IN (
				SELECT StockTransferId
				FROM #StockTransferIds
				)
			AND STD.IsDeleted = 0
			AND ST.IsDeleted = 0

		IF EXISTS (
		SELECT 1 
		FROM dbo.StockTransfer ST
		INNER JOIN #StockTransferIds SS ON ST.StockTransferId = SS.StockTransferId
		WHERE ST.StockTransferStatus NOT IN (0, 1)
		)
		BEGIN
			SET @ReturnMessage = 'Stock transfer can only be cancelled when its status is Draft or In Transit.';
			RETURN;
		END
		
		BEGIN TRAN cancelTransfer;

		SET @CurrentRow = 1;

		SELECT @TotalRows = COUNT(*)
		FROM #StockTrasferDetail;

		WHILE @CurrentRow <= @TotalRows
		BEGIN
			UPDATE pl
			SET pl.WareHouseQuantity = ISNULL(p.Quantity, 0)
			FROM #StockTrasferDetail pl
			LEFT JOIN dbo.ProductQuantitiesByWarehouse p WITH (NOLOCK) ON p.ProductId = pl.ProductId
				AND p.WarehouseId = pl.WareHouseId;

			UPDATE pl
			SET pl.ProductQuantity = ISNULL(p.Quantity, 0)
			FROM #StockTrasferDetail pl
			LEFT JOIN dbo.ProductQuantities p WITH (NOLOCK) ON p.ProductId = pl.ProductId;

			SELECT @CurrentProductId = ProductId
				,@Quantity = Quantity
				,@OldQuantity = WareHouseQuantity
				,@SellableOldQuantity = ProductQuantity
				,@Status = StockTransferStatus
				,@WarehouseId = WareHouseId
				,@StockTransferNumber = StockTransferNumber
				,@FromWarehouseName = FromWarehouseName
			FROM #StockTrasferDetail
			WHERE RowID = @CurrentRow;

			IF @Status = 1
			BEGIN
				SET @NewWarehouseQuantity = @OldQuantity + @Quantity;
				SET @Description = 'Inventory has been updated from ' + FORMAT(@OldQuantity, '0.00') + ' to ' + FORMAT(@NewWarehouseQuantity, '0.00') + ' (' + CASE 
						WHEN @Quantity >= 0
							THEN '+'
						ELSE ''
						END + FORMAT(@Quantity, '0.00') + ') in the ' + ISNULL(@FromWarehouseName, '') + ' warehouse as the Stock Transfer was cancelled ' + @StockTransferNumber + '.';

				EXEC dbo.AddProductWarehouseQuantity @TenantId = @TenantId
					,@UserId = @UserId
					,@ProductId = @CurrentProductId
					,@WarehouseId = @WarehouseId
					,@OrderNo = @StockTransferNumber
					,@Quantity = @Quantity
					,@Description = @Description;

				SET @SellableNewQuantity = @SellableOldQuantity + @Quantity;
				SET @Description = 'Inventory has been updated from ' + FORMAT(@SellableOldQuantity, '0.00') + ' to ' + FORMAT(@SellableNewQuantity, '0.00') + ' (' + CASE 
						WHEN @Quantity >= 0
							THEN '+'
						ELSE ''
						END + FORMAT(@Quantity, '0.00') + ') as the Stock Transfer was cancelled ' + @StockTransferNumber + '.';

				EXEC dbo.AddProductSaleableQuantity @TenantId = @TenantId
					,@UserId = @UserId
					,@ProductId = @CurrentProductId
					,@OrderNo = @StockTransferNumber
					,@Quantity = @Quantity
					,@Description = @Description;
			END

			SET @CurrentRow = @CurrentRow + 1;
		END

		UPDATE ST
		SET ST.IsDeleted = 1
			,ST.UpdatedBy = @UserId
			,ST.UpdatedDate = @Dt
		FROM dbo.StockTransfer ST
		INNER JOIN #StockTransferIds SS ON ST.StockTransferId = SS.StockTransferId

		UPDATE ST
		SET ST.IsDeleted = 1
			,ST.UpdatedBy = @UserId
			,ST.UpdatedDate = @Dt
		FROM dbo.StockTransferDetail ST
		INNER JOIN #StockTransferIds SS ON ST.StockTransferId = SS.StockTransferId

		COMMIT TRAN cancelTransfer;

		SELECT CAST(1 AS BIT) AS [Status]
			,'The cancellation of the transfer order was successful.' AS [Message]
			,NULL AS [Data]
			,NULL AS [Error];
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN cancelTransfer;
		END
		DECLARE @ObjectName VARCHAR(500)
		
		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE();

		SELECT CAST(0 AS BIT) AS [Status]
			,'The cancellation of the transfer order was unsuccessful.' AS [Message]
			,NULL AS [Data]
			,@ErrorMsg AS [Error];

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

		
	END CATCH
END

GO

