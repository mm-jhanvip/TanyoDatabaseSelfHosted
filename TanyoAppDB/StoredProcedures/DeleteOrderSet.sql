/*    
	EXEC [dbo].[DeleteOrderSet]
		@OrderSetId = 35
		,@DeletedBy = 1
		,@TenantId = 2
*/
CREATE PROCEDURE [dbo].[DeleteOrderSet] (
	@OrderSetId BIGINT
	,@DeletedBy BIGINT
	,@TenantId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Status INT = 0
		,@Message VARCHAR(200)
		,@ErrorMsg VARCHAR(MAX)
		,@OrderId BIGINT
		,@OrderSubjectTypeId INT
		,@dtoffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@dtutc DATETIME = GETUTCDATE()
		,@OrderStatus INT

	BEGIN TRY
		-- Get OrderId  
		SELECT @OrderId = OrderId
		FROM OrderSets WITH (NOLOCK)
		WHERE OrderSetId = @OrderSetId

		IF (
				SELECT COUNT(1)
				FROM OrderSetItems osi WITH (NOLOCK)
				INNER JOIN OrderSets os WITH (NOLOCK) ON os.OrderSetId = osi.OrderSetId
				WHERE osi.OrderId = @OrderId
					AND osi.IsDeleted = 0
					AND osi.IsDeleted = 0
					AND os.OrderSetId <> @OrderSetId
				) = 1
		BEGIN
			SET @Status = - 1
			SET @Message = 'You cannot delete the last item as it is the last item in the order.'

			SELECT @Status AS [Status]
				,@Message AS [Message]
				,NULL AS [Data]
				,@Message AS [Error]
		END

		BEGIN TRAN delOrderSet

		SELECT @OrderStatus = STATUS
		FROM Orders WITH (NOLOCK)
		WHERE OrderId = @OrderId

		-- Get SubjectTypeId for Orders  
		SELECT @OrderSubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Orders'
			AND TenantId = @TenantId
			AND IsDeleted = 0

		-- Delete related product charges  
		DELETE
		FROM OrderProductCharges
		WHERE OrderSetItemId IN (
				SELECT OrderSetItemId
				FROM OrderSetItems WITH (NOLOCK)
				WHERE OrderSetId = @OrderSetId
				)
			AND OrderId = @OrderId

		-- Cursor for inventory update and logging  
		DECLARE @Temp_OrderSetItems TABLE (
			ID INT PRIMARY KEY IDENTITY
			,OrderSetItemId BIGINT
			,SubjectId BIGINT
			,SubjectTypeId INT
			)

		INSERT INTO @Temp_OrderSetItems (
			OrderSetItemId
			,SubjectId
			,SubjectTypeId
			)
		SELECT OrderSetItemId
			,SubjectId
			,SubjectTypeId
		FROM OrderSetItems WITH (NOLOCK)
		WHERE OrderSetId = @OrderSetId
			AND IsDeleted = 0

		DECLARE @OrderSetItemId BIGINT
			,@SubjectId BIGINT
			,@SubjectTypeId INT
			,@ProductName VARCHAR(150)
			,@ItemType VARCHAR(50)
			,@cnt INT
			,@inc INT = 1

		SELECT @cnt = COUNT(1)
		FROM @Temp_OrderSetItems

		WHILE (@cnt >= @inc)
		BEGIN
			SELECT @OrderSetItemId = NULL
				,@SubjectId = NULL
				,@SubjectTypeId = NULL
				,@ProductName = NULL
				,@ItemType = NULL

			SELECT @OrderSetItemId = OrderSetItemId
				,@SubjectId = SubjectId
				,@SubjectTypeId = SubjectTypeId
			FROM @Temp_OrderSetItems
			WHERE ID = @inc

			BEGIN TRY
				-- Get ItemType Name  
				SELECT @ItemType = SubjectTypeName
				FROM SubjectTypes WITH (NOLOCK)
				WHERE SubjectTypeId = @SubjectTypeId

				-- Get Product or Fabric Name  
				IF @ItemType = 'Products'
				BEGIN
					SELECT @ProductName = ProductTitle
					FROM Products WITH (NOLOCK)
					WHERE ProductId = @SubjectId
				END
				ELSE
				BEGIN
					SELECT @ProductName = Title
					FROM Fabrics WITH (NOLOCK)
					WHERE FabricId = @SubjectId
				END

				-- Check Stock on Hold and Release if any
				EXEC [dbo].[ReleaseStockOnHoldByOrderSetItemId] @OrderSetItemId = @OrderSetItemId
					,@OrderId = @OrderId
					,@UserId = @DeletedBy

				IF @OrderStatus >= 2
					AND @OrderStatus NOT IN (
						5
						,8
						) --Delivered, Declined
				BEGIN
					-- Update Inventory  
					EXEC UpdateInventoryByOrderSetItem @OrderId = @OrderId
						,@OrderSetItemId = @OrderSetItemId
						,@TenantId = @TenantId
						,@UserId = @DeletedBy
				END

				-- Log Activity  
				DECLARE @ActivityDescription VARCHAR(MAX);

				SET @ActivityDescription = ISNULL(@ItemType, '') + ' ' + ISNULL(@ProductName, '') + ' has been deleted.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @OrderSubjectTypeId
					,@SubjectId = @OrderId
					,@Description = @ActivityDescription
					,@Action = 'DELETE'
					,@CreatedBy = @DeletedBy
					,@CreatedDate = @dtoffset
					,@CreatedUTCDate = @dtutc;
			END TRY

			BEGIN CATCH
				-- Continue loop but log error  
				PRINT 'Error in loop: ' + ERROR_MESSAGE()
			END CATCH

			SET @inc = @inc + 1
		END

		-- Soft delete items  
		UPDATE OrderSetItems
		SET IsDeleted = 1
			,UpdatedDate = @dtoffset
			,UpdatedUTCDate = @dtutc
		WHERE OrderSetId = @OrderSetId
			AND IsDeleted = 0

		-- Soft delete OrderSet  
		UPDATE OrderSets
		SET IsDeleted = 1
			,UpdatedDate = @dtoffset
			,UpdatedUTCDate = @dtutc
		WHERE OrderSetId = @OrderSetId
			AND IsDeleted = 0

		COMMIT TRAN delOrderSet

		SET @Status = 1
		SET @Message = 'The deletion of your order set was successful.'

		-- Final output  
		SELECT @Status AS [Status]
			,@Message AS [Message]
			,NULL AS [Data]
			,NULL AS [Error]

		-- Recalculate Order Amount after delete order set item
		EXEC dbo.UpdateOrderRefreshInquiry @OrderId = @OrderId
			,@TenantId = @TenantId
			,@UserId = @DeletedBy
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)

		IF @@TRANCOUNT > 0
			ROLLBACK TRAN delOrderSet

		SET @ErrorMsg = ERROR_MESSAGE()
		SET @Message = 'The deletion of your order set was unsuccessful.'
		SET @ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT @Status AS [Status]
			,@Message AS [Message]
			,NULL AS [Data]
			,@ErrorMsg AS [Error]

		RETURN
	END CATCH
END

GO

