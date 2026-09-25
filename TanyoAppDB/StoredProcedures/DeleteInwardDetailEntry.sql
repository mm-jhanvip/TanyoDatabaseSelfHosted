CREATE PROCEDURE [dbo].[DeleteInwardDetailEntry] 
     @InwardDetailsId BIGINT
	,@UserId INT
	,@ReturnMessage NVARCHAR(255) = '' OUTPUT
	,@Status BIT = 0 OUTPUT
	,@ReturnInwardId BIGINT = NULL OUTPUT
	,@ImagePath VARCHAR(MAX) = '' OUTPUT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @CreatedBy INT
			,@TenantId INT
			,@InwardEntryNumber VARCHAR(20)
			,@InwardType INT
			,@InwardNo VARCHAR(50)
			,@PoNo VARCHAR(50)
			,@OrderNo VARCHAR(50)
			,@StockTransferNo VARCHAR(50)
			,@Description NVARCHAR(MAX)
			,@WHDescription NVARCHAR(MAX)
			,@Sign VARCHAR(1)
			,@Dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@UTCDt DATETIME2 = SYSUTCDATETIME()
			,@ErrorMsg VARCHAR(MAX)
			,@Result VARCHAR(500)
			,@ProductId BIGINT
			,@Quantity DECIMAL(18, 2)
			,@WarehouseId BIGINT
			,@TargetWarehouseId BIGINT
			,@WarehouseName VARCHAR(255)
			,@OldInventory DECIMAL(18, 2)
			,@NewInventory DECIMAL(18, 2)
			,@OldWHInventory DECIMAL(18, 2)
			,@NewWHInventory DECIMAL(18, 2)
			,@UpdateQuantity DECIMAL(18, 2)
			,@CancelRef VARCHAR(200)
			,@IsDeleted INT
			,@ActiveDetailCount INT
			,@InwardId BIGINT
			,@FromWarehouseId BIGINT;

		SELECT @InwardId = IDE.InwardId
			,@ProductId = IDE.ProductId
			,@Quantity = IDE.Quantity
			,@WarehouseId = IDE.WarehouseId
			,@CreatedBy = IE.CreatedBy
			,@TenantId = IE.TenantId
			,@InwardEntryNumber = IE.InwardEntryNumber
			,@InwardType = IE.InwardType
			,@PoNo = IE.PoNumber
			,@OrderNo = O.OrderNo
			,@StockTransferNo = ST.StockTransferNo
			,@IsDeleted = IDE.IsDeleted
			,@FromWarehouseId = ST.FromWarehouseId
			,@ActiveDetailCount = (
				SELECT COUNT(1)
				FROM dbo.InwardDetailsEntry
				WHERE InwardId = IDE.InwardId
					AND IsDeleted = 0
				)
			,@ImagePath = IDE.ImagePath
		FROM dbo.InwardDetailsEntry IDE
		INNER JOIN dbo.InwardEntry IE ON IDE.InwardId = IE.InwardId
		LEFT JOIN dbo.StockTransfer ST ON IE.StockTransferId = ST.StockTransferId
		LEFT JOIN dbo.Orders O ON O.OrderId = IE.OrderId
		WHERE IDE.InwardDetailsId = @InwardDetailsId
			AND IDE.IsDeleted = 0;

		IF @InwardDetailsId IS NULL
			OR @InwardDetailsId = 0
			OR @IsDeleted = 1
		BEGIN
			SET @ReturnMessage = 'Inward Entry Detail Not Found or already deleted.';
			SET @Status = 0;
			SET @ReturnInwardId = @InwardId;
			SET @ImagePath = @ImagePath;

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

			SET @ReturnMessage = 'This Inward is managed by ' + ISNULL(@FullName, 'another user') + '. You cannot update it.';
			SET @Status = 0;
			SET @ReturnInwardId = @InwardId;
			SET @ImagePath = @ImagePath;

			RETURN;
		END

		SELECT @ActiveDetailCount = COUNT(1)
		FROM dbo.InwardDetailsEntry
		WHERE InwardId = @InwardId
			AND IsDeleted = 0;

		IF @ActiveDetailCount <= 1
		BEGIN
			SET @ReturnMessage = 'You cannot delete the last inward detail. Please delete the entire Inward instead.';
			SET @Status = 0;
			SET @ReturnInwardId = @InwardId;
			SET @ImagePath = @ImagePath;

			RETURN;
		END

		BEGIN TRANSACTION DeleteInwardDetailEntry;

		SET @OldInventory = 0;

		SELECT @OldInventory = ISNULL(Quantity, 0)
		FROM dbo.ProductQuantities
		WHERE ProductId = @ProductId;

		SET @UpdateQuantity = - ABS(@Quantity);
		SET @NewInventory = @OldInventory + @UpdateQuantity;
		SET @Sign = CASE 
				WHEN @UpdateQuantity > 0
					THEN '+'
				ELSE ''
				END;

		DECLARE @StrOld VARCHAR(50) = CAST(@OldInventory AS VARCHAR(50));
		DECLARE @StrNew VARCHAR(50) = CAST(@NewInventory AS VARCHAR(50));
		DECLARE @StrUpdate VARCHAR(50) = CAST(@UpdateQuantity AS VARCHAR(50));

		IF @InwardType = 1
			SET @CancelRef = 'Manual Inward was cancelled ' + ISNULL(@InwardEntryNumber, '');
		ELSE IF @InwardType = 2
			SET @CancelRef = 'PO Inward was cancelled ' + ISNULL(@PoNo, '');
		ELSE IF @InwardType = 3
			SET @CancelRef = 'Sales Return was cancelled ' + ISNULL(@OrderNo, '');
		ELSE
			SET @CancelRef = 'Stock Transfer was cancelled ' + ISNULL(@StockTransferNo, '');

		SET @Description = 'Inventory has been updated from ' + @StrOld + ' to ' + @StrNew + ' (' + @Sign + @StrUpdate + ') as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

		IF @InwardType <> 4
		BEGIN
			EXEC dbo.DeductProductSaleableQuantity @TenantId = @TenantId
				,@UserId = @UserId
				,@ProductId = @ProductId
				,@OrderNo = @OrderNo
				,@Quantity = @Quantity
				,@Description = @Description
				,@InwardNo = @InwardEntryNumber
				,@StockTransferNo = @StockTransferNo
				,@PurchaseOrderNo = @PoNo
				,@Result = @Result OUTPUT;
		END

		SELECT @TargetWarehouseId = Id
			,@WarehouseName = Name
		FROM dbo.Warehouse
		WHERE Id = @WarehouseId;

		IF @TargetWarehouseId IS NULL
			OR @TargetWarehouseId <= 0
		BEGIN
			SELECT TOP 1 @TargetWarehouseId = Id
				,@WarehouseName = Name
			FROM dbo.Warehouse
			WHERE Name = 'Other';
		END

		IF @TargetWarehouseId IS NOT NULL
			AND @TargetWarehouseId > 0
		BEGIN
			SET @OldWHInventory = 0;

			SELECT @OldWHInventory = ISNULL(Quantity, 0)
			FROM dbo.ProductQuantitiesByWarehouse(NOLOCK)
			WHERE ProductId = @ProductId
				AND WarehouseId = @TargetWarehouseId;

			SET @NewWHInventory = @OldWHInventory + @UpdateQuantity;

			DECLARE @StrWHOld VARCHAR(50) = CAST(@OldWHInventory AS VARCHAR(50));
			DECLARE @StrWHNew VARCHAR(50) = CAST(@NewWHInventory AS VARCHAR(50));

			SET @WHDescription = 'Inventory has been updated from ' + @StrWHOld + ' to ' + @StrWHNew + ' (' + @Sign + @StrUpdate + ') in the ' + ISNULL(@WarehouseName, 'Other') + ' warehouse as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

			EXEC dbo.DeductProductWarehouseQuantity @TenantId = @TenantId
				,@UserId = @UserId
				,@ProductId = @ProductId
				,@WarehouseId = @TargetWarehouseId
				,@OrderNo = @OrderNo
				,@Quantity = @Quantity
				,@InwardNo = @InwardEntryNumber
				,@StockTransferNo = @StockTransferNo
				,@PurchaseOrderNo = @PoNo
				,@Description = @WHDescription
				,@Result = @Result OUTPUT;
		END

		IF @FromWarehouseId IS NOT NULL
			AND @FromWarehouseId > 0
		BEGIN
			SELECT @WarehouseName = Name
			FROM dbo.Warehouse
			WHERE Id = @FromWarehouseId;

			SET @OldWHInventory = 0;
			SET @NewWHInventory = 0;
			SET @UpdateQuantity = 0;

			SELECT @OldWHInventory = ISNULL(Quantity, 0)
			FROM dbo.ProductQuantitiesByWarehouse WITH (NOLOCK)
			WHERE ProductId = @ProductId
				AND WarehouseId = @FromWarehouseId;

			SET @UpdateQuantity = ABS(@Quantity);
			SET @NewWHInventory = @OldWHInventory + @UpdateQuantity;
			SET @StrWHOld = CAST(@OldWHInventory AS VARCHAR(50));
			SET @StrWHNew = CAST(@NewWHInventory AS VARCHAR(50));
			SET @StrUpdate = CAST(@UpdateQuantity AS VARCHAR(50));
			SET @WHDescription = 'Inventory has been updated from ' + @StrWHOld + ' to ' + @StrWHNew + ' (+' + @StrUpdate + ') in the ' + ISNULL(@WarehouseName, 'Other') + ' warehouse as the ' + LTRIM(RTRIM(@CancelRef)) + '.';

			EXEC dbo.AddProductWarehouseQuantity @TenantId = @TenantId
				,@UserId = @UserId
				,@ProductId = @ProductId
				,@WarehouseId = @FromWarehouseId
				,@OrderNo = @OrderNo
				,@Quantity = @Quantity
				,@Description = @WHDescription
				,@InwardNo = @InwardEntryNumber
				,@StockTransferNo = @StockTransferNo
				,@PurchaseOrderNo = @PoNo;
		END

		UPDATE dbo.InwardDetailsEntry
		SET IsDeleted = 1
			,UpdatedBy = @UserId
			,UpdatedDate = @Dt
			,UpdatedUTCDate = @UTCDt
		WHERE InwardDetailsId = @InwardDetailsId;

		COMMIT TRANSACTION DeleteInwardDetailEntry;

		SET @ReturnMessage = 'The cancellation of the InwardDetail was successful.'
		SET @Status = 1;
		SET @ReturnInwardId = @InwardId;
		SET @ImagePath = @ImagePath;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRANSACTION DeleteInwardDetailEntry;
		END

		DECLARE @ObjectName VARCHAR(500) = OBJECT_NAME(@@PROCID);

		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SET @ReturnMessage = @ErrorMsg
		SET @Status = 0;
		SET @ReturnInwardId = @InwardId;
		SET @ImagePath = @ImagePath;
	END CATCH
END

GO

