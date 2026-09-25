/*
EXEC [dbo].[DeleteInward] @InwardId = 62499, @UserId = 13312
*/
CREATE PROCEDURE [dbo].[DeleteInward] 
     @InwardId BIGINT
	,@UserId INT
	,@ReturnMessage NVARCHAR(255) = '' OUTPUT
	,@ReturnInwardId BIGINT = NULL OUTPUT
	,@Status BIT = 0 OUTPUT
	,@ImagePaths NVARCHAR(MAX) = '' OUTPUT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @CreatedBy INT
			,@TenantId INT
			,@InwardEntryNumber VARCHAR(20)
			,@InwardType INT
			,@PoNo VARCHAR(50)
			,@OrderNo VARCHAR(50)
			,@StockTransferNo VARCHAR(50)
			,@StockTransferId BIGINT
			,@Description VARCHAR(MAX)
			,@Sign VARCHAR(1)
			,@Dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@UTCDt DATETIME2 = SYSUTCDATETIME()
			,@ErrorMsg VARCHAR(MAX)
			,@InwardNo VARCHAR(50)
			,@Result VARCHAR(500)
			,@ObjectName VARCHAR(500)
			,@OldWHInventory DECIMAL(18, 2)
			,@NewWHInventory DECIMAL(18, 2)
			,@WHDescription VARCHAR(MAX)
			,@StrWHOld VARCHAR(50)
			,@StrWHNew VARCHAR(50)
			,@CurrentInwardDetailsId BIGINT
			,@CurrentProductId BIGINT
			,@CurrentQuantity DECIMAL(18, 2)
			,@CurrentWarehouseId BIGINT
			,@OldInventory DECIMAL(18, 2)
			,@NewInventory DECIMAL(18, 2)
			,@UpdateQuantity DECIMAL(18, 2)
			,@CurrentRow INT
			,@TotalRows INT
			,@StrOld VARCHAR(50)
			,@StrNew VARCHAR(50)
			,@StrUpdate VARCHAR(50)
			,@ProductId BIGINT
			,@TargetWarehouseId BIGINT
			,@FromWarehouseId BIGINT
			,@WarehouseName VARCHAR(50)
			,@CancelRef VARCHAR(200);

		SELECT @CreatedBy = IE.CreatedBy
			,@InwardEntryNumber = IE.InwardEntryNumber
			,@TenantId = IE.TenantId
			,@InwardType = IE.InwardType
			,@PoNo = IE.PoNumber
			,@OrderNo = O.OrderNo
			,@StockTransferNo = ST.StockTransferNo
			,@StockTransferId = ST.StockTransferId
			,@InwardNo = IE.InwardEntryNumber
			,@FromWarehouseId = ST.FromWarehouseId
		FROM dbo.InwardEntry IE
		LEFT JOIN Orders O ON O.OrderId = IE.OrderId
		LEFT JOIN StockTransfer ST ON ST.StockTransferId = IE.StockTransferId
		WHERE IE.InwardId = @InwardId
			AND IE.IsDeleted = 0;

		IF @@ROWCOUNT = 0
		BEGIN
			SET @ReturnInwardId = @InwardId;
			SET @Status = 0;
			SET @ReturnMessage = 'Inward Entry Not Found or already deleted.';
			SET @ImagePaths = '';

			RETURN;
		END

		IF @CreatedBy <> @UserId
		BEGIN
			DECLARE @FullName NVARCHAR(255);

			SELECT @FullName = CONCAT (
					FirstName
					,' '
					,LastName
					)
			FROM dbo.AspNetUsers
			WHERE UserId = @CreatedBy;

			SET @ReturnInwardId = @InwardId;
			SET @Status = 0;
			SET @ReturnMessage = 'This Inward is managed by ' + ISNULL(@FullName, 'another user') + '. You cannot update it.';
			SET @ImagePaths = '';

			RETURN;
		END

		CREATE TABLE #InwardDetailsEntries (
			RowID INT IDENTITY(1, 1)
			,InwardDetailsId BIGINT
			,ProductId BIGINT
			,Quantity DECIMAL(18, 2)
			,WarehouseId BIGINT
			,ImagePath NVARCHAR(MAX)
			,OldInventory DECIMAL(18, 2)
			,NewInventory DECIMAL(18, 2)
			,UpdateQuantity DECIMAL(18, 2)
			);

		BEGIN TRANSACTION;

		INSERT INTO #InwardDetailsEntries (
			InwardDetailsId
			,ProductId
			,Quantity
			,WarehouseId
			,ImagePath
			)
		SELECT InwardDetailsId
			,ProductId
			,Quantity
			,WarehouseId
			,ImagePath
		FROM dbo.InwardDetailsEntry WITH (NOLOCK)
		WHERE InwardId = @InwardId
			AND IsDeleted = 0;

		SET @TotalRows = @@ROWCOUNT;

		UPDATE dbo.InwardEntry
		SET IsDeleted = 1
			,UpdatedBy = @UserId
			,UpdatedDate = @Dt
			,UpdatedUTCDate = @UTCDt
		WHERE InwardId = @InwardId;

		SET @CurrentRow = 1;

		WHILE @CurrentRow <= @TotalRows
		BEGIN
			SELECT @CurrentInwardDetailsId = InwardDetailsId
				,@CurrentProductId = ProductId
				,@CurrentQuantity = Quantity
				,@CurrentWarehouseId = WarehouseId
			FROM #InwardDetailsEntries
			WHERE RowID = @CurrentRow;

			SET @OldInventory = 0;

			SELECT @OldInventory = ISNULL(Quantity, 0)
			FROM dbo.ProductQuantities
			WHERE ProductId = @CurrentProductId;

			SET @UpdateQuantity = - ABS(@CurrentQuantity);
			SET @NewInventory = @OldInventory + @UpdateQuantity;
			SET @Sign = CASE 
					WHEN @UpdateQuantity > 0
						THEN '+'
					ELSE ''
					END;

			UPDATE #InwardDetailsEntries
			SET OldInventory = @OldInventory
				,NewInventory = @NewInventory
				,UpdateQuantity = @UpdateQuantity
			WHERE RowID = @CurrentRow;

			SET @StrOld = CAST(CAST(@OldInventory AS FLOAT) AS VARCHAR(50));
			SET @StrNew = CAST(CAST(@NewInventory AS FLOAT) AS VARCHAR(50));
			SET @StrUpdate = CAST(CAST(@UpdateQuantity AS FLOAT) AS VARCHAR(50));

			IF @InwardType = 1
				SET @CancelRef = 'Manual Inward was cancelled ' + ISNULL(@InwardEntryNumber, '');
			ELSE IF @InwardType = 2
				SET @CancelRef = 'PO Inward was cancelled ' + ISNULL(@PoNo, '');
			ELSE IF @InwardType = 2
				SET @CancelRef = 'Sales Return was cancelled ' + ISNULL(@OrderNo, '');
			ELSE
				SET @CancelRef = 'Stock Transfer was cancelled ' + ISNULL(@StockTransferNo, '');

			SET @Description = 'Inventory has been updated from ' + @StrOld + ' to ' + @StrNew + ' (' + @Sign + @StrUpdate + ') as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

			IF @InwardType <> 4
			BEGIN
				EXEC dbo.DeductProductSaleableQuantity @TenantId = @TenantId
					,@UserId = @UserId
					,@ProductId = @CurrentProductId
					,@OrderNo = @OrderNo
					,@Quantity = @CurrentQuantity
					,@Description = @Description
					,@InwardNo = @InwardEntryNumber
					,@StockTransferNo = @StockTransferNo
					,@PurchaseOrderNo = @PoNo
					,@Result = @Result OUTPUT;
			END

			SET @TargetWarehouseId = @CurrentWarehouseId;

			SELECT @WarehouseName = Name
			FROM dbo.Warehouse WITH (NOLOCK)
			WHERE Id = @TargetWarehouseId;

			IF @TargetWarehouseId IS NULL
				OR @TargetWarehouseId <= 0
			BEGIN
				SELECT TOP 1 @TargetWarehouseId = Id
				FROM dbo.Warehouse WITH (NOLOCK)
				WHERE Name = 'Other';
			END

			IF @TargetWarehouseId IS NOT NULL
				AND @TargetWarehouseId > 0
			BEGIN
				SET @OldWHInventory = 0;

				SELECT @OldWHInventory = ISNULL(Quantity, 0)
				FROM dbo.ProductQuantitiesByWarehouse WITH (NOLOCK)
				WHERE ProductId = @ProductId
					AND WarehouseId = @TargetWarehouseId;

				SET @NewWHInventory = @OldWHInventory + @UpdateQuantity;
				SET @StrWHOld = CAST(@OldWHInventory AS VARCHAR(50));
				SET @StrWHNew = CAST(@NewWHInventory AS VARCHAR(50));
				SET @WHDescription = 'Inventory has been updated from ' + @StrWHNew + ' to ' + @StrOld + ' (' + @Sign + @StrUpdate + ') in the ' + ISNULL(@WarehouseName, 'Other') + ' warehouse as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

				EXEC dbo.DeductProductWarehouseQuantity @TenantId = @TenantId
					,@UserId = @UserId
					,@ProductId = @CurrentProductId
					,@WarehouseId = @TargetWarehouseId
					,@OrderNo = @OrderNo
					,@Quantity = @CurrentQuantity
					,@Description = @WHDescription
					,@InwardNo = @InwardEntryNumber
					,@StockTransferNo = @StockTransferNo
					,@PurchaseOrderNo = @PoNo
					,@Result = @Result OUTPUT;

				IF @FromWarehouseId IS NOT NULL
					AND @FromWarehouseId > 0
				BEGIN
					SELECT @WarehouseName = Name
					FROM dbo.Warehouse WITH (NOLOCK)
					WHERE Id = @FromWarehouseId;

					SET @OldWHInventory = 0;
					SET @NewWHInventory = 0;
					SET @UpdateQuantity = 0;

					SELECT @OldWHInventory = ISNULL(Quantity, 0)
					FROM dbo.ProductQuantitiesByWarehouse WITH (NOLOCK)
					WHERE ProductId = @CurrentProductId
						AND WarehouseId = @FromWarehouseId;

					SET @UpdateQuantity = ABS(@CurrentQuantity);
					SET @NewWHInventory = @OldWHInventory + @UpdateQuantity;
					SET @StrWHOld = CAST(@OldWHInventory AS VARCHAR(50));
					SET @StrWHNew = CAST(@NewWHInventory AS VARCHAR(50));
					SET @StrUpdate = CAST(@UpdateQuantity AS VARCHAR(50));
					SET @WHDescription = 'Inventory has been updated from ' + @StrWHOld + ' to ' + @StrWHNew + ' (+' + @StrUpdate + ') in the ' + ISNULL(@WarehouseName, 'Other') + ' warehouse as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

					EXEC dbo.AddProductWarehouseQuantity @TenantId = @TenantId
						,@UserId = @UserId
						,@ProductId = @CurrentProductId
						,@WarehouseId = @FromWarehouseId
						,@OrderNo = @OrderNo
						,@Quantity = @CurrentQuantity
						,@Description = @WHDescription
						,@InwardNo = @InwardEntryNumber
						,@StockTransferNo = @StockTransferNo
						,@PurchaseOrderNo = @PoNo;
				END
			END

			SET @CurrentRow = @CurrentRow + 1;
		END

		UPDATE IDE
		SET IDE.IsDeleted = 1
			,IDE.UpdatedBy = @UserId
			,IDE.UpdatedDate = @Dt
			,IDE.UpdatedUTCDate = @UTCDt
		FROM dbo.InwardDetailsEntry IDE
		INNER JOIN #InwardDetailsEntries ID ON IDE.InwardDetailsId = ID.InwardDetailsId;

		IF @StockTransferId IS NOT NULL
			OR @StockTransferId > 0
		BEGIN
			UPDATE StockTransfer
			SET StockTransferStatus = 0
			WHERE StockTransferId = @StockTransferId

			UPDATE StockTransferDetail
			SET StockTransferDetailStatus = 0
				,ReceivedQuantity = 0
			WHERE StockTransferId = @StockTransferId
		END

		COMMIT TRANSACTION;

		SELECT @ImagePaths = ISNULL(STRING_AGG(ImagePath, ','), '')
		FROM #InwardDetailsEntries;

		SET @ReturnInwardId = @InwardId;
		SET @Status = 1;
		SET @ReturnMessage = 'Inward entry deleted successfully.';
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SET @ErrorMsg = ERROR_MESSAGE();
		SET @ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SET @ReturnInwardId = @InwardId;
		SET @Status = 0;
		SET @ReturnMessage = @ErrorMsg;
		SET @ImagePaths = '';
	END CATCH
END

GO

