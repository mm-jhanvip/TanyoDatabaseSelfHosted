/*To transfer all stock of one warehouse to another warehouse

--First prepare json of the products which needs to transfer
SELECT '    {
                "stockTransferDetailId": 0,
                "productId": '+CAST(pqbw.ProductId AS VARCHAR(10))+',
                "quantity": '+CAST(pqbw.Quantity AS VARCHAR(50))+'
            },' 
FROM ProductQuantitiesByWarehouse pqbw
INNER JOIN Products p ON p.ProductId = pqbw.ProductId
WHERE TenantId = 191
AND WarehouseId = 202
AND pqbw.Quantity >0

--Step2 copy whole json cretaed from the above query and put it into the ProductList json and run the procedure

DECLARE @ReturnMessage NVARCHAR(1024);

EXEC [dbo].[SaveStockTransfer]
    @TenantId = 191,
    @UserId = 9047,
    @JsonObject = N'{
        "stockTransferId": 0,
        "fromWarehouseId": 202,
        "toWarehouseId": 208,
        "remarks": "Stock transfer for all products",
        "status": 1,
        "productsList": [
                          {
                            "stockTransferDetailId": 0,
                            "productId": 296480,
                            "quantity": 2
                          },
                          {
                            "stockTransferDetailId": 0,
                            "productId": 296481,
                            "quantity": 1
                          },
                          {
                            "stockTransferDetailId": 0,
                            "productId": 296482,
                            "quantity": 1
                          }
                    ]
    }',
@ReturnMessage = @ReturnMessage OUTPUT;

SELECT @ReturnMessage AS ReturnMessage;


Step3: Go to the tenant portal and Mark that stock transfer as received
*/
CREATE PROCEDURE [dbo].[SaveStockTransfer] (
	@TenantId INT
	,@UserId INT
	,@JsonObject NVARCHAR(MAX)
	,@ReturnMessage NVARCHAR(1024) = '' OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StockTransferId INT
		,@FromWarehouseId INT
		,@ToWarehouseId INT
		,@Remarks VARCHAR(200)
		,@Status INT
		,@ProductsJsonList NVARCHAR(MAX)
		,@CreatedDate DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@TotalRows INT
		,@CurrentRow INT
		,@CurrentProductId BIGINT
		,@Quantity DECIMAL(18, 2)
		,@OldQuantity DECIMAL(18, 2)
		,@NewQuantity DECIMAL(18, 2)
		,@Description VARCHAR(500)
		,@Result VARCHAR(500)
		,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@SellableNewQuantity DECIMAL(18, 2)
		,@SellableOldQuantity DECIMAL(18, 2)
		,@FromWarehouseName VARCHAR(50)
		,@ToWarehouseName VARCHAR(50);
	DECLARE @NextSeq INT
		,@StockTransferNo NVARCHAR(20)
		,@NewStockTransferId INT;

	IF OBJECT_ID('tempdb..#ProductList') IS NOT NULL
		DROP TABLE #ProductList;

	IF OBJECT_ID('tempdb..#WareHouseNames') IS NOT NULL
		DROP TABLE #WareHouseNames;

	SELECT @StockTransferId = ISNULL(stockTransferId, 0)
		,@FromWarehouseId = fromWarehouseId
		,@ToWarehouseId = toWarehouseId
		,@Remarks = remarks
		,@Status = Status
		,@ProductsJsonList = productsList
	FROM OPENJSON(@JsonObject) WITH (
			stockTransferId INT '$.stockTransferId'
			,fromWarehouseId INT '$.fromWarehouseId'
			,toWarehouseId INT '$.toWarehouseId'
			,remarks VARCHAR(200) '$.remarks'
			,Status INT '$.status'
			,productsList NVARCHAR(MAX) '$.productsList' AS JSON
			);

	SELECT ID
		,Name
	INTO #WareHouseNames
	FROM Warehouse
	WHERE @FromWarehouseId = Id
		OR @ToWarehouseId = Id

	SELECT @FromWarehouseName = Name
	FROM #WareHouseNames
	WHERE ID = @FromWarehouseId;

	SELECT @ToWarehouseName = Name
	FROM #WareHouseNames
	WHERE ID = @ToWarehouseId;

	CREATE TABLE #ProductList (
		RowID INT IDENTITY(1, 1)
		,StockTransferDetailId INT
		,ProductId BIGINT
		,Quantity DECIMAL(18, 2)
		,OldQuantity DECIMAL(18, 2)
		,SellableOldQuantity DECIMAL(18, 2)
		)

	IF @ProductsJsonList IS NOT NULL
	BEGIN
		INSERT INTO #ProductList (
			StockTransferDetailId
			,ProductId
			,Quantity
			)
		SELECT StockTransferDetailId
			,ProductId
			,Quantity
		FROM OPENJSON(@ProductsJsonList) WITH (
				StockTransferDetailId INT '$.stockTransferDetailId'
				,ProductId INT '$.productId'
				,Quantity DECIMAL(18, 2) '$.quantity'
				);
	END;

	IF @FromWarehouseId = @ToWarehouseId
	BEGIN
		SET @ReturnMessage = 'Source and Destination warehouse cannot be same.';

		RETURN;
	END;

	IF @StockTransferId > 0
	BEGIN
		DECLARE @ExistingStatus INT;

		SELECT @ExistingStatus = StockTransferStatus
			,@StockTransferNo = StockTransferNo
		FROM StockTransfer
		WHERE StockTransferId = @StockTransferId
			AND TenantId = @TenantId;

		IF @ExistingStatus IS NULL
		BEGIN
			SET @ReturnMessage = 'Stock Transfer not found.';

			RETURN;
		END

		IF @ExistingStatus <> 0
		BEGIN
			SET @ReturnMessage = 'Can not Update Stock Transfer which is already InTransit.';

			RETURN;
		END
	END;

	UPDATE pl
	SET pl.OldQuantity = ISNULL(p.Quantity, 0)
	FROM #ProductList pl
	LEFT JOIN ProductQuantitiesByWarehouse p WITH (NOLOCK) ON p.ProductId = pl.ProductId
		AND p.WarehouseId = @FromWarehouseId;

	UPDATE pl
	SET pl.SellableOldQuantity = ISNULL(p.Quantity, 0)
	FROM #ProductList pl
	LEFT JOIN ProductQuantities p WITH (NOLOCK) ON p.ProductId = pl.ProductId

	IF EXISTS (
			SELECT 1
			FROM #ProductList
			WHERE OldQuantity < Quantity
			)
	BEGIN
		SET @ReturnMessage = 'Insufficient stock available in the source warehouse for one or more products.';

		RETURN;
	END;

	BEGIN
		BEGIN TRANSACTION SaveStockTransfer;

		BEGIN TRY
			IF @StockTransferId > 0
			BEGIN
				UPDATE ST
				SET ST.FromWarehouseId = @FromWarehouseId
					,ST.ToWarehouseId = @ToWarehouseId
					,ST.Remarks = @Remarks
					,ST.StockTransferStatus = @Status
					,ST.UpdatedBy = @UserID
					,ST.UpdatedDate = @DateOffset
				FROM StockTransfer ST
				WHERE ST.StockTransferId = @StockTransferId
					AND ST.TenantId = @TenantId;

				SET @NewStockTransferId = @StockTransferId;

				UPDATE StockTransferDetail
				SET IsDeleted = 1
				WHERE StockTransferId = @NewStockTransferId
					AND ProductId NOT IN (
						SELECT ProductId
						FROM #ProductList
						);

				UPDATE std
				SET std.TransferQuantity = pl.Quantity
					,std.IsDeleted = 0
					,std.StockTransferDetailStatus = @Status
					,std.UpdatedBy = @UserID
					,std.UpdatedDate = @DateOffset
				FROM StockTransferDetail std
				INNER JOIN #ProductList pl ON pl.StockTransferDetailId = std.StockTransferDetailId

				INSERT INTO StockTransferDetail (
					StockTransferId
					,ProductId
					,TransferQuantity
					,IsDeleted
					,StockTransferDetailStatus
					,CreatedBy
					,CreatedDate
					)
				SELECT @NewStockTransferId
					,pl.ProductId
					,pl.Quantity
					,0
					,@Status
					,@UserId
					,@CreatedDate
				FROM #ProductList pl
				WHERE NOT EXISTS (
						SELECT 1
						FROM StockTransferDetail std
						WHERE std.StockTransferId = @NewStockTransferId
							AND std.ProductId = pl.ProductId
						);
			END
			ELSE
			BEGIN
				SELECT @StockTransferNo = [dbo].[GetStockTransferNumber](@TenantID);

				UPDATE TenantConfigurations
				SET StockTransferNumberCounter = StockTransferNumberCounter + 1
				WHERE TenantId = @TenantId

				INSERT INTO StockTransfer (
					FromWarehouseId
					,ToWarehouseId
					,Remarks
					,TenantId
					,StockTransferNo
					,CreatedBy
					,StockTransferStatus
					,CreatedDate
					)
				VALUES (
					@FromWarehouseId
					,@ToWarehouseId
					,@Remarks
					,@TenantId
					,@StockTransferNo
					,@UserId
					,@Status
					,@CreatedDate
					);

				SET @NewStockTransferId = SCOPE_IDENTITY();

				INSERT INTO StockTransferDetail (
					StockTransferId
					,ProductId
					,TransferQuantity
					,IsDeleted
					,StockTransferDetailStatus
					,CreatedBy
					,CreatedDate
					)
				SELECT @NewStockTransferId
					,ProductId
					,Quantity
					,0
					,@Status
					,@UserId
					,@CreatedDate
				FROM #ProductList;
			END

			IF @Status = 1
			BEGIN
				UPDATE ST
				SET ST.TransferDate = CAST(GETDATE() AS DATE)
				FROM StockTransfer ST
				WHERE StockTransferId = @NewStockTransferId

				SET @CurrentRow = 1;

				SELECT @TotalRows = COUNT(*)
				FROM #ProductList;

				WHILE @CurrentRow <= @TotalRows
				BEGIN
					SELECT @CurrentProductId = ProductId
						,@Quantity = Quantity
						,@OldQuantity = OldQuantity
						,@SellableOldQuantity = SellableOldQuantity
					FROM #ProductList
					WHERE RowID = @CurrentRow;

					SET @NewQuantity = ISNULL(@OldQuantity, 0) - ISNULL(@Quantity, 0);
					SET @Description = 'Inventory has been updated from ' + FORMAT(ISNULL(@OldQuantity, 0), '0.00') + ' to ' + FORMAT(ISNULL(@NewQuantity, 0), '0.00') + ' (' + CASE 
							WHEN ISNULL(- @Quantity, 0) >= 0
								THEN '+'
							ELSE ''
							END + FORMAT(ISNULL(- @Quantity, 0), '0.00') + ') in the ' + ISNULL(@FromWarehouseName, '') + ' warehouse for Stock Transfer ' + ISNULL(@StockTransferNo, '') + '.';

					EXEC dbo.DeductProductWarehouseQuantity @TenantId = @TenantId
						,@UserId = @UserId
						,@ProductId = @CurrentProductId
						,@WarehouseId = @FromWarehouseId
						,@OrderNo = @StockTransferNo
						,@Quantity = @Quantity
						,@Description = @Description
						,@Result = @Result OUTPUT;

					SET @SellableNewQuantity = ISNULL(@SellableOldQuantity, 0) - ISNULL(@Quantity, 0);
					SET @Description = 'Inventory has been updated from ' + FORMAT(ISNULL(@SellableOldQuantity, 0), '0.00') + ' to ' + FORMAT(ISNULL(@SellableNewQuantity, 0), '0.00') + ' (' + CASE 
							WHEN ISNULL(- @Quantity, 0) >= 0
								THEN '+'
							ELSE ''
							END + FORMAT(ISNULL(- @Quantity, 0), '0.00') + ') for StockTransferOrder ' + ISNULL(@StockTransferNo, '') + '.';

					EXEC dbo.DeductProductSaleableQuantity @TenantId = @TenantId
						,@UserId = @UserId
						,@ProductId = @CurrentProductId
						,@OrderNo = @StockTransferNo
						,@Quantity = @Quantity
						,@Description = @Description
						,@Result = @Result OUTPUT

					SET @CurrentRow = @CurrentRow + 1;
				END
			END

			COMMIT TRANSACTION SaveStockTransfer;

			SET @ReturnMessage = 'Stock Transfer ' + ISNULL(@StockTransferNo, '') + CASE 
					WHEN @StockTransferId > 0
						THEN ' updated successfully'
					ELSE ' created successfully'
					END;

			SELECT @NewStockTransferId AS [StockTransferId]
				,@ReturnMessage AS [Message];
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION SaveStockTransfer;

			DECLARE @ObjectName VARCHAR(500)
				,@ErrorMsg VARCHAR(MAX);

			SET @ObjectName = OBJECT_NAME(@@PROCID);
			SET @ErrorMsg = ERROR_MESSAGE();

			EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
				,@ErrorMsg = @ErrorMsg;
		END CATCH
	END;
END;

GO

