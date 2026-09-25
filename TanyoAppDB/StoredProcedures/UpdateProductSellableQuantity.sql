CREATE PROCEDURE [dbo].[UpdateProductSellableQuantity] (
	@ProductQuantityId BIGINT
	,@Quantity DECIMAL(18, 4)
	,@MinimumLimit DECIMAL(18, 4)
	,@Remarks NVARCHAR(1000)
	,@UserId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- 1. Declare and Initialize Date Variables
		DECLARE @DateNow DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DateUtcNow DATETIME = GETUTCDATE()
			,@ProductId BIGINT
			,@OldQuantity DECIMAL(18, 4)
			,@ProductName NVARCHAR(500);

		-- 3. Fetch missing parameters for Logging
		SELECT @OldQuantity = pq.Quantity
			,@ProductId = pq.ProductId
			,@ProductName = p.ProductTitle
		FROM dbo.ProductQuantities pq WITH (NOLOCK)
		INNER JOIN dbo.Products p WITH (NOLOCK) ON pq.ProductId = p.ProductId
		WHERE pq.ProductQuantityId = @ProductQuantityId;

		BEGIN TRANSACTION UpdatePQTran;

		-- 4. Update the Quantity
		UPDATE dbo.ProductQuantities
		SET Quantity = @Quantity
			,LastModifiedBy = @UserId
			,LastModifiedDate = @DateNow
			,LastModifiedUTCDate = @DateUtcNow
			,MinimumLimit = @MinimumLimit
		WHERE ProductQuantityId = @ProductQuantityId;

		-- 5. Insert into InventoryLogs
		IF ISNULL(@OldQuantity, 0) <> ISNULL(@Quantity, 0)
		BEGIN
			INSERT INTO dbo.InventoryLogs (
				ProductId
				,WarehouseId
				,Description
				,Remarks
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			VALUES (
				@ProductId
				,0
				,'Inventory has been replaced from ' + CAST(ISNULL(TRY_CAST(@OldQuantity AS NUMERIC(18, 2)), 0) AS VARCHAR(50)) + ' to ' + CAST(ISNULL(TRY_CAST(@Quantity AS NUMERIC(18, 2)), 0) AS VARCHAR(50)) + ' for ' + ISNULL(@ProductName, '')
				,@Remarks
				,@UserId
				,@DateNow
				,@DateUtcNow
				);
		END

		COMMIT TRANSACTION UpdatePQTran;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION UpdatePQTran;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog 
			 @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

