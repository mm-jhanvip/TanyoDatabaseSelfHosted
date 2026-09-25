/*
	EXEC dbo.AddProductSaleableQuantity
		@TenantId = 0
		,@UserId = 0
		,@ProductId = 0
		,@Quantity = 0
		,@Description = ''
*/
CREATE   PROC [dbo].[AddProductSaleableQuantity]
(
	@TenantId INT
	,@UserId BIGINT
	,@ProductId BIGINT
	,@Quantity NUMERIC(18, 2)
	,@Description VARCHAR(500)
	,@MinimumLimit INT = NULL
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
		BEGIN TRANSACTION AddProductSaleableQuantity

			DECLARE @DtNowOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
					,@DtNowUTC DATETIME = GETUTCDATE()
					,@DtNow DATETIME = CAST(GETDATE() AS DATE)

			UPDATE pq
			SET pq.Quantity = pq.Quantity + @Quantity
				,pq.QuantityDate = @DtNow
				,pq.MinimumLimit = CASE 
									WHEN @MinimumLimit IS NULL
										THEN pq.MinimumLimit
										ELSE @MinimumLimit
									END
				,pq.LastModifiedBy = @UserId
				,pq.LastModifiedDate = @DtNowOffset
				,pq.LastModifiedUTCDate = @DtNowUTC
			FROM ProductQuantities pq
			WHERE pq.ProductId = @ProductId

			INSERT INTO dbo.InventoryLogs
			(
				ProductId
				,Description
				,CreatedBy
				,Remarks
				,OrderNo
				,InwardNo
				,PurchaseOrderNo
				,StockTransferNo
			)
			SELECT @ProductId
				,@Description
				,@UserId
				,@Remarks
				,@OrderNo
				,@InwardNo
				,@PurchaseOrderNo
				,@StockTransferNo
		
		-- Commit a transaction
		COMMIT TRAN AddProductSaleableQuantity
	END TRY
	BEGIN CATCH
	

		DECLARE @ErrorSeverity INT
		SELECT @ErrorSeverity = ERROR_SEVERITY()

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

			-- Rollback the transaction
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN AddProductSaleableQuantity
			
		RAISERROR(@ErrorMsg, @ErrorSeverity, 1)
	END CATCH
END

GO

