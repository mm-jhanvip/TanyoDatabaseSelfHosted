/*
	EXEC dbo.AddProductWarehouseQuantity
		@TenantId = 0
		,@UserId = 0
		,@ProductId = 0
		,@WarehouseId = 0
		,@Quantity = 0
		,@Description = ''
*/
CREATE PROC [dbo].[AddProductWarehouseQuantity]
(
	@TenantId INT
	,@UserId BIGINT
	,@ProductId BIGINT
	,@WarehouseId INT
	,@Quantity NUMERIC(18, 2)
	,@Description VARCHAR(500)
	,@Remarks VARCHAR(1000) = NULL
	,@OrderNo VARCHAR(50) = NULL
	,@InwardNo VARCHAR(50) = NULL
	,@PurchaseOrderNo VARCHAR(50) = NULL
	,@StockTransferNo VARCHAR(50) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		-- Start a transaction
		BEGIN TRANSACTION AddProductWarehouseQuantity

			DECLARE @DtNowOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
					,@DtNowUTC DATETIME = GETUTCDATE()
					,@DtNow DATETIME = CAST(GETDATE() AS DATE)

			UPDATE pqw
			SET pqw.Quantity = pqw.Quantity + @Quantity
				,pqw.QuantityDate = @DtNow
				,pqw.LastModifiedBy = @UserId
				,pqw.LastModifiedDate = @DtNowOffset
				,pqw.LastModifiedUTCDate = @DtNowUTC
			FROM ProductQuantitiesByWarehouse pqw
			WHERE pqw.ProductId = @ProductId
			AND pqw.WarehouseId = @WarehouseId

			INSERT INTO dbo.InventoryLogs
			(
				ProductId
				,WarehouseId
				,Description
				,CreatedBy
				,Remarks
				,OrderNo
				,InwardNo
				,PurchaseOrderNo
				,StockTransferNo
			)
			SELECT @ProductId
				,@WarehouseId
				,@Description
				,@UserId
				,@Remarks
				,@OrderNo
				,@InwardNo
				,@PurchaseOrderNo
				,@StockTransferNo
		
		-- Commit a transaction
		COMMIT TRAN AddProductWarehouseQuantity
	END TRY
	BEGIN CATCH
		-- Rollback the transaction
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN AddProductWarehouseQuantity

		DECLARE @ErrorSeverity INT
		SELECT @ErrorSeverity = ERROR_SEVERITY()

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

		RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
	END CATCH
END

GO

