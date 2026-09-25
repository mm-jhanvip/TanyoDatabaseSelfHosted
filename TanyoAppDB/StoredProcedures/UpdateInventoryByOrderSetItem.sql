/*
	EXEC [dbo].[UpdateInventoryByOrderSetItem]
		@OrderID = 1
		,@OrderSetItemId=1
		,@TenantID = 1
		,@UserID = 1	
*/
CREATE PROCEDURE [dbo].[UpdateInventoryByOrderSetItem] (
	@OrderId BIGINT
	,@OrderSetItemId BIGINT
	,@TenantId INT
	,@UserId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Start a transaction
		BEGIN TRANSACTION UpdateInventoryByOrderSetItem;

		DECLARE @OrderNo VARCHAR(50)
			,@productSubjectTypeId INT
			,@productQuantitiesSubjectTypeId INT
			,@rawMaterialSubjectTypeId INT
			,@OrderSubjectTypeId INT
			,@Status BIT
			,@Message NVARCHAR(MAX)
			,@JsonObject NVARCHAR(MAX)
			,@Error NVARCHAR(MAX)
			,@ProductId BIGINT
			,@DT DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DTUTC DATETIME = GETUTCDATE()
			,@LogDescription VARCHAR(500)

		SELECT @OrderNo = OrderNo
		FROM Orders
		WHERE OrderId = @OrderId;

		-- Manage Product Quantity
		SELECT @productSubjectTypeId = SubjectTypeId
		FROM SubjectTypes
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		SELECT @productQuantitiesSubjectTypeId = SubjectTypeId
		FROM SubjectTypes
		WHERE SubjectTypeName = 'ProductQuantity'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		SELECT *
		INTO #orderSetItemByOrderId
		FROM OrderSetItems WITH (NOLOCK)
		WHERE IsDeleted = 0
			AND ItemStatus <> 3
			AND (
				OrderSetItemId = @OrderSetItemId
				OR ParentOrderSetItemId = @OrderSetItemId
				);

		-- Temporary table to hold the result
		CREATE TABLE #OrderProductQuantity (
			Id INT IDENTITY
			,OrderId INT
			,ProductQuantityId BIGINT
			,ProductId INT
			,ProductQuantity NUMERIC(18, 2)
			,Quantity NUMERIC(18, 2)
			,Status BIT
			);

		-- Calculate and insert data into the temporary table
		INSERT INTO #OrderProductQuantity (
			OrderId
			,ProductQuantityId
			,ProductId
			,ProductQuantity
			,Quantity
			,Status
			)
		SELECT @OrderId AS OrderId
			,p.ProductQuantityId
			,o.SubjectId AS ProductId
			,ISNULL(p.Quantity, 0) AS ProductQuantity
			,SUM(o.Quantity) AS Quantity
			,1 -- Set Status Based on Tenants Flag
		FROM #orderSetItemByOrderId o
		LEFT JOIN ProductQuantities p ON o.SubjectId = p.ProductId
		WHERE o.OrderId = @OrderId
			AND o.SubjectTypeId = @productSubjectTypeId
		--AND o.OrderSetItemId=@OrderSetItemId
		GROUP BY p.ProductQuantityId
			,o.SubjectId
			,p.Quantity;

		-- Declare variables
		DECLARE @ProductQuantityId BIGINT;
		DECLARE @Quantity NUMERIC(18, 2);
		DECLARE @Index INT = 1;
		DECLARE @Count INT = (
				SELECT MAX(Id)
				FROM #OrderProductQuantity
				)

		WHILE @Index <= @Count
		BEGIN
			SET @ProductId = 0

			SELECT @ProductQuantityId = ProductQuantityId
				,@Quantity = Quantity
				,@ProductId = ProductId
			FROM #OrderProductQuantity
			WHERE Id = @Index

			-- Get oldQuantity for log description, then add back via centralized proc
			DECLARE @oldQuantity NUMERIC(18, 2);

			SELECT @oldQuantity = pq.Quantity
			FROM ProductQuantities pq
			WHERE pq.ProductQuantityId = @ProductQuantityId;

			SET @LogDescription = 'Inventory has been updated from ' + CAST(@oldQuantity AS NVARCHAR(100)) + ' to ' + CAST((@oldQuantity + @Quantity) AS NVARCHAR(100)) + ' (+' + CAST(@Quantity AS NVARCHAR(100)) + ') for order ' + CAST(@OrderNo AS NVARCHAR(50))

			-- Add back to ProductQuantities + its own InventoryLogs entry
			EXEC dbo.AddProductSaleableQuantity @TenantId = @TenantId
				,@UserId = @UserId
				,@ProductId = @ProductId
				,@Quantity = @Quantity
				,@Description = @LogDescription

			SET @Index = @Index + 1
		END

		-- Update ItemStatus in OrderSetItems to 0 for all records
		UPDATE OrderSetItems
		SET ItemStatus = 0
		WHERE OrderSetItemId = @OrderSetItemId;

		-- Commit the transaction if everything is successful
		COMMIT TRAN UpdateInventoryByOrderSetItem;

		IF @Status IS NULL
			OR @Status = 1
		BEGIN
			SET @Status = 1;

			SELECT @JsonObject = (
					SELECT *
					FROM OrderSetItems WITH (NOLOCK)
					WHERE OrderSetItemId = @OrderSetItemId
					FOR JSON AUTO
					);

			SELECT @Message = 'The deletion of your order set item was successful.';

			SET @Error = NULL;

			SELECT @Status AS [Status]
				,@Message AS [Message]
				,@JsonObject AS [Data]
				,@Error AS [Error]
		END
	END TRY

	BEGIN CATCH
		-- Rollback the transaction in case of an error
		ROLLBACK TRANSACTION UpdateInventoryByOrderSetItem;

		SET @Status = 0;

		SELECT @JsonObject = (
				SELECT *
				FROM OrderSetItems WITH (NOLOCK)
				WHERE OrderSetItemId = @OrderSetItemId
				FOR JSON AUTO
				);

		IF @Message IS NULL
		BEGIN
			SELECT @Message = 'The deletion of your order set item was not successful.';
		END

		IF @Error IS NULL
		BEGIN
			SELECT @Error = ERROR_MESSAGE();
		END

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = @Error

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

		SELECT @Status AS [Status]
			,@Message AS [Message]
			,@JsonObject AS [Data]
			,@Error AS [Error]
	END CATCH;
END;

GO

