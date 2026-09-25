CREATE PROCEDURE [dbo].[SetOrderSetItmemOnHold] (
	@OrderSetItemId BIGINT
	,@OrderId BIGINT
	,@TimePeriod VARCHAR(20)
	,@UserId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN SetOrderSetItmemOnHold;

		SET NOCOUNT ON;

		DECLARE @NowUTC DATETIME = GETUTCDATE();
		DECLARE @NowUTCOffset DATETIMEOFFSET = SYSDATETIMEOFFSET();
		DECLARE @StockOnHoldId BIGINT
			,@Status BIT
			,@Message VARCHAR(1024)
		DECLARE @TenantId INT
			,@ProductId BIGINT
			,@OrderNo VARCHAR(50)
			,@HoldQuantity NUMERIC(18, 2)
			,@OldQuantity NUMERIC(18, 2)
			,@DeductDescription VARCHAR(500)
			,@DeductResult INT

		IF NOT EXISTS (
				SELECT 1
				FROM OrderSetItems osi WITH (NOLOCK)
				INNER JOIN StockOnHold soh WITH (NOLOCK) ON soh.OrderSetItemId = osi.OrderSetItemId
					AND soh.IsStockOnHold = 1
					AND osi.IsQuantityOnHold = 1
				WHERE osi.OrderSetItemId = @OrderSetItemId
					AND osi.OrderId = @OrderId
				)
		BEGIN
			SELECT @TenantId = o.TenantId
				,@ProductId = osi.SubjectId
				,@OrderNo = o.OrderNo
				,@HoldQuantity = osi.Quantity
				,@OldQuantity = pq.Quantity
			FROM OrderSetItems osi WITH (NOLOCK)
			INNER JOIN Orders o WITH (NOLOCK) ON o.OrderId = osi.OrderId
			INNER JOIN ProductQuantities pq WITH (NOLOCK) ON pq.ProductId = osi.SubjectId
			WHERE osi.OrderSetItemId = @OrderSetItemId
				AND osi.OrderId = @OrderId

			SET @DeductDescription = CONCAT (
					'Inventory put on hold and updated from '
					,@OldQuantity
					,' to '
					,@OldQuantity - @HoldQuantity
					,' ( - '
					,@HoldQuantity
					,' ) '
					,' for '
					,@OrderNo
					,'.'
					)

			EXEC dbo.DeductProductSaleableQuantity @TenantId = @TenantId
				,@UserId = @UserId
				,@ProductId = @ProductId
				,@OrderNo = @OrderNo
				,@Quantity = @HoldQuantity
				,@Description = @DeductDescription
				,@Result = @DeductResult OUTPUT

			UPDATE osi
			SET osi.IsQuantityOnHold = 1
				,osi.UpdatedBy = @UserId
				,osi.UpdatedDate = @NowUTCOffset
				,osi.UpdatedUTCDate = @NowUTC
			FROM OrderSetItems osi
			WHERE osi.OrderSetItemId = @OrderSetItemId
				AND osi.OrderId = @OrderId

			INSERT INTO StockOnHold (
				ProductId
				,Quantity
				,OrderId
				,OrderSetItemId
				,TimePeriod
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				,IsStockOnHold
				)
			SELECT OSI.SubjectId
				,OSI.Quantity
				,@OrderId
				,@OrderSetItemId
				,@TimePeriod
				,@UserId
				,@NowUTCOffset
				,@NowUTC
				,1
			FROM OrderSetItems OSI
			WHERE OSI.OrderSetItemId = @OrderSetItemId
				AND OSI.OrderId = @OrderId
				AND OSI.IsQuantityOnHold = 1
		END

		COMMIT TRAN SetOrderSetItmemOnHold;

		SET @StockOnHoldId = SCOPE_IDENTITY();
		SET @Status = 1;
		SET @Message = 'Product set on hold successfully';

		SELECT @StockOnHoldId AS StockOnHoldId
			,@Status AS [Status]
			,@Message AS [Message]
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SetOrderSetItmemOnHold;

		DECLARE @ObjectName VARCHAR(500)

		SET @Status = 0;
		SET @StockOnHoldId = NULL;
		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @Message = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @Message;

		SELECT @StockOnHoldId AS StockOnHoldId
			,@Status AS [Status]
			,@Message AS [Message]
	END CATCH
END

GO

