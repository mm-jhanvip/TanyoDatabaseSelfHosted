
/*
	EXEC dbo.PopulateProductSaleableQuantity
		@TenantId = 0
		,@UserId = 0
		,@ProductId = 0
		,@Quantity = 0
		,@Description = ''
*/
CREATE   PROC [dbo].[PopulateProductSaleableQuantity]
(
	@TenantId INT
	,@UserId BIGINT
	,@ProductId BIGINT
	,@Quantity NUMERIC(18, 2)
	,@Description VARCHAR(500)
	,@MinimumLimit INT = NULL
	,@Remarks VARCHAR(1000) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		-- Start a transaction
		BEGIN TRANSACTION PopulateProductSaleableQuantity

			DECLARE @DtNow DATETIME = CAST(GETDATE() AS DATE)

			IF NOT EXISTS (SELECT TOP 1 1
							FROM ProductQuantities pq WITH (NOLOCK)
							WHERE pq.ProductId = @ProductId)
			BEGIN
				INSERT INTO ProductQuantities
				(
					ProductId
					,Quantity
					,QuantityDate
					,MinimumLimit
					,LastModifiedBy
				)
				SELECT
					@ProductId
					,@Quantity
					,@DtNow
					,ISNULL(@MinimumLimit, 0)
					,@UserId
			
				INSERT INTO dbo.InventoryLogs
				(
					ProductId
					,Description
					,CreatedBy
					,Remarks
				)
				SELECT @ProductId
					,@Description
					,@UserId
					,@Remarks
			END
		
		-- Commit a transaction
		COMMIT TRAN PopulateProductSaleableQuantity
	END TRY
	BEGIN CATCH
		-- Rollback the transaction
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN PopulateProductSaleableQuantity

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

