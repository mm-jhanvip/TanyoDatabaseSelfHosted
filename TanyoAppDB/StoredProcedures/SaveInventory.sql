/*
EXEC [dbo].[SaveInventory]
	@TenantId = 1207,
    @ProductId = 402785,
    @ReorderPoint = 55.00,
    @SaleableQuantity = 30.00,
    @ProductWarehouseQuantitiesJson = N'[
        {"ProductQuantityByWarehouseId": 295221, "WarehouseId": 10258, "Quantity": 10.00},
        {"ProductQuantityByWarehouseId": 0, "WarehouseId": 10259, "Quantity": 5.00},
        {"ProductQuantityByWarehouseId": 0, "WarehouseId": 10260, "Quantity": 15.00}
    ]',
    @ProductQuantityId = 373586,
    @Remarks = N'Updated multiple warehouse stocks',
    @UserId = 10
*/
CREATE PROCEDURE [dbo].[SaveInventory] (
	@TenantId BIGINT
	,@ProductId BIGINT
	,@ReorderPoint DECIMAL(18, 4)
	,@SaleableQuantity DECIMAL(18, 4)
	,@ProductWarehouseQuantitiesJson NVARCHAR(MAX)
	,@ProductQuantityId BIGINT
	,@Remarks NVARCHAR(1000) = NULL
	,@UserId BIGINT
	,@Status BIT = NULL OUTPUT
	,@ReturnMessage NVARCHAR(500) = NULL OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @DateNow DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DateUtcNow DATETIME = GETUTCDATE();
		/*========================================================
          1. Get Product & Existing Inventory Details
        ========================================================*/
		DECLARE @TotalWarehouseQuantity DECIMAL(18, 4) = 0;
		DECLARE @ProductQuantity DECIMAL(18, 4) = 0;
		DECLARE @ProductName NVARCHAR(500);

		SELECT @ProductName = ProductTitle
		FROM dbo.Products WITH (NOLOCK)
		WHERE ProductId = @ProductId;

		SELECT @ProductQuantity = Quantity
		FROM dbo.ProductQuantities WITH (NOLOCK)
		WHERE ProductQuantityId = @ProductQuantityId;

		/*========================================================
          2. Parse JSON & Load Warehouse Info
        ========================================================*/
		DROP TABLE IF EXISTS #WarehouseTable;

			-- Added an Id column to facilitate the WHILE loop
			CREATE TABLE #WarehouseTable (
				Id INT IDENTITY(1, 1) PRIMARY KEY
				,ProductQuantityByWarehouseId BIGINT
				,WarehouseId BIGINT
				,WarehouseName NVARCHAR(250)
				,OldQuantity DECIMAL(18, 4)
				,NewQuantity DECIMAL(18, 4)
				);

		-- Insert parsed JSON with Warehouse Name and OldQuantity
		INSERT INTO #WarehouseTable (
			ProductQuantityByWarehouseId
			,WarehouseId
			,WarehouseName
			,OldQuantity
			,NewQuantity
			)
		SELECT J.ProductQuantityByWarehouseId
			,J.WarehouseId
			,ISNULL(W.Name, '') AS WarehouseName
			,PWQ.Quantity AS OldQuantity -- Leave as NULL if it doesn't exist yet
			,J.Quantity AS NewQuantity
		FROM OPENJSON(@ProductWarehouseQuantitiesJson) WITH (
				ProductQuantityByWarehouseId BIGINT '$.ProductQuantityByWarehouseId'
				,WarehouseId BIGINT '$.WarehouseId'
				,Quantity DECIMAL(18, 4) '$.Quantity'
				) J
		LEFT JOIN dbo.Warehouse W WITH (NOLOCK) ON W.Id = J.WarehouseId
		LEFT JOIN dbo.ProductQuantitiesByWarehouse PWQ WITH (NOLOCK) ON PWQ.ProductQuantityByWarehouseId = J.ProductQuantityByWarehouseId;

		-- Calculate total warehouse quantity
		SELECT @TotalWarehouseQuantity = ISNULL(SUM(NewQuantity), 0)
		FROM #WarehouseTable;

		/*========================================================
          3. Validate Saleable Quantity = Warehouse Quantity
        ========================================================*/
		--IF ISNULL(@SaleableQuantity, 0) <> ISNULL(@TotalWarehouseQuantity, 0)
		--BEGIN
		--	SET @Status = 0;
		--	SET @ReturnMessage = 'Total Saleable Quantity (' + CAST(ISNULL(@SaleableQuantity, 0) AS VARCHAR(50)) + ') must be equal to Total Warehouse Quantity (' + CAST(ISNULL(@TotalWarehouseQuantity, 0) AS VARCHAR(50)) + ').';
		--	SELECT @Status AS [Status],
		--	       @ReturnMessage AS ReturnMessage;
		--	RETURN;
		--END;
		BEGIN TRANSACTION InventoryUpdateTransaction;

		/*========================================================
          4. Update Saleable Quantity / Stock Count (Using separate SP)
        ========================================================*/
		EXEC [dbo].[UpdateProductSellableQuantity] @ProductQuantityId = @ProductQuantityId
			,@Quantity = @SaleableQuantity
			,@MinimumLimit = @ReorderPoint
			,@Remarks = @Remarks
			,@UserId = @UserId;

		/*========================================================
          5. Update or Insert Warehouse Quantity (Using WHILE Loop)
        ========================================================*/
		DECLARE @Cur_ProductQuantityByWarehouseId BIGINT;
		DECLARE @Cur_WarehouseId BIGINT;
		DECLARE @Cur_WarehouseName NVARCHAR(250);
		DECLARE @Cur_NewQuantity DECIMAL(18, 4);
		DECLARE @Cur_OldQuantity DECIMAL(18, 4);
		DECLARE @Cur_Description NVARCHAR(500);
		DECLARE @Counter INT = 1;
		DECLARE @MaxCount INT = 0;

		-- Get the total number of records to process
		SELECT @MaxCount = COUNT(1)
		FROM #WarehouseTable;

		WHILE @Counter <= @MaxCount
		BEGIN
			SELECT @Cur_ProductQuantityByWarehouseId = ProductQuantityByWarehouseId
				,@Cur_WarehouseId = WarehouseId
				,@Cur_WarehouseName = WarehouseName
				,@Cur_NewQuantity = NewQuantity
				,@Cur_OldQuantity = OldQuantity
			FROM #WarehouseTable
			WHERE Id = @Counter;

			IF ISNULL(@Cur_ProductQuantityByWarehouseId, 0) = 0
				AND ISNULL(@Cur_NewQuantity, 0) <> 0
			BEGIN
				SET @Cur_Description = ISNULL(@Cur_WarehouseName, '') + ' Warehouse inventory has been added with ' + CAST(ISNULL(TRY_CAST(@Cur_NewQuantity AS NUMERIC(18, 2)), 0) AS VARCHAR(50)) + ' for ' + ISNULL(@ProductName, '');

				EXEC [dbo].[PopulateProductWarehouseQuantity] @TenantId = @TenantId
					,@UserId = @UserId
					,@ProductId = @ProductId
					,@WarehouseId = @Cur_WarehouseId
					,@Quantity = @Cur_NewQuantity
					,@Description = @Cur_Description
					,@Remarks = @Remarks;
			END
			ELSE IF ISNULL(@Cur_ProductQuantityByWarehouseId, 0) > 0
				AND ISNULL(@Cur_OldQuantity, 0) <> ISNULL(@Cur_NewQuantity, 0)
			BEGIN
				EXEC [dbo].[UpdateProductQuantityByWarehouse] @ProductQuantityByWarehouseId = @Cur_ProductQuantityByWarehouseId
					,@Quantity = @Cur_NewQuantity
					,@UserId = @UserId
					,@Remarks = @Remarks;
			END

			SET @Counter = @Counter + 1;
		END

		/*========================================================
          7. Commit Transaction
        ========================================================*/
		COMMIT TRANSACTION InventoryUpdateTransaction;

		SET @Status = 1;
		SET @ReturnMessage = 'Inventory details saved successfully.';

		SELECT @Status AS [Status]
			,@ReturnMessage AS ReturnMessage;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION InventoryUpdateTransaction;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SET @Status = 0;
		SET @ReturnMessage = @ErrorMsg;

		SELECT @Status AS [Status]
			,@ReturnMessage AS ReturnMessage;
	END CATCH
END;

GO

