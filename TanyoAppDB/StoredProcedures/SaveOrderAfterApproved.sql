CREATE PROCEDURE [dbo].[SaveOrderAfterApproved] (
	@OrderId BIGINT
	,@OrderSetItemId BIGINT
	,@UpdatedQuantity [numeric](18, 2)
	,@TenantId INT
	,@UserId INT
	,@Comment NVARCHAR(MAX) = NULL
	,@Remarks NVARCHAR(MAX) = NULL
	,@TentativeDeliveryDate DATE = NULL
	,@ReturnStatus BIT = 0 OUTPUT
	,@ReturnMessage VARCHAR(100) = NULL OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @OrderNo VARCHAR(50)
			,@productSubjectTypeId INT
			,@productQuantitiesSubjectTypeId INT
			,@rawMaterialSubjectTypeId INT
			,@OrderSubjectTypeId INT
			,@FabricSubjectTypeId INT
			,@Status BIT
			,@Message NVARCHAR(MAX)
			,@JsonObject NVARCHAR(MAX)
			,@Error NVARCHAR(MAX)
			,@CheckProductStock BIT
			,@CheckRawMaterialStock BIT
			,@StockAvailable BIT
			,@ActualDifference [numeric] (
			18
			,2
			) = 0 - @UpdatedQuantity
			,@ProductId BIGINT
			,@OrderStatus INT
			,@IsManufacturing BIT
			,@IsAutoManufacture BIT
			,@LastSeq INT
			,@DT DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DTUTC DATETIME = GETUTCDATE()
			,@DeductResult INT
			,@LogDescription VARCHAR(500);

		IF OBJECT_ID('tempdb..#TempOrderSetItemIds') IS NOT NULL
			DROP TABLE #TempOrderSetItemIds

		IF OBJECT_ID('tempdb..#orderSetItemByOrderId') IS NOT NULL
			DROP TABLE #orderSetItemByOrderId

		IF OBJECT_ID('tempdb..#OrderProductQuantity') IS NOT NULL
			DROP TABLE #OrderProductQuantity

		-- Check if the order exists and the condition is met  
		SELECT @OrderNo = OrderNo
			,@OrderStatus = [Status]
		FROM Orders WITH (NOLOCK)
		WHERE OrderId = @OrderId;

		SELECT @LastSeq = ISNULL(MAX(CAST(RIGHT(DeliveryNo, CHARINDEX('_', REVERSE(DeliveryNo)) - 1) AS INT)), 0)
		FROM OrderSetItems
		WHERE OrderId = @OrderId
			AND DeliveryNo IS NOT NULL;

		SELECT @LastSeq = @LastSeq + 1

		SELECT @CheckProductStock = CheckProductStock
			,@CheckRawMaterialStock = CheckRawMaterialStock
			,@IsAutoManufacture = IsAutoManufacture
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId;

		-- Manage Product Quantity  
		SELECT @productSubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		SELECT @productQuantitiesSubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'ProductQuantity'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		SELECT @FabricSubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Fabrics'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		SELECT *
		INTO #orderSetItemByOrderId
		FROM OrderSetItems OSI WITH (NOLOCK)
		WHERE OrderId = @OrderId
			AND SubjectTypeId = @productSubjectTypeId
			AND IsDeleted = 0
			AND OrderSetItemId = @OrderSetItemId;

		CREATE TABLE #OrderProductQuantity (
			Id INT IDENTITY
			,OrderId INT
			,ProductQuantityId BIGINT
			,ProductId INT
			,ProductQuantity INT
			,Quantity [NUMERIC](18, 2)
			,Status BIT
			);

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
			,@UpdatedQuantity AS Quantity
			,1
		FROM #orderSetItemByOrderId o
		LEFT JOIN ProductQuantities p WITH (NOLOCK) ON o.SubjectId = p.ProductId
		GROUP BY p.ProductQuantityId
			,o.SubjectId
			,p.Quantity;

		DECLARE @ProductQuantityId BIGINT;
		DECLARE @Quantity [numeric] (
			18
			,2
			);
		DECLARE @Index INT = 1;
		DECLARE @Count INT = (
				SELECT MAX(Id)
				FROM #OrderProductQuantity
				);

		SELECT @ProductQuantityId = ProductQuantityId
			,@Quantity = Quantity
			,@ProductId = ProductId
		FROM #OrderProductQuantity

		DECLARE @oldQuantity [numeric] (
			18
			,2
			);

		SELECT @oldQuantity = pq.Quantity
		FROM ProductQuantities pq WITH (NOLOCK)
		WHERE pq.ProductQuantityId = @ProductQuantityId;

		SET @LogDescription = 'Inventory has been updated from ' + CAST(@oldQuantity AS NVARCHAR(10)) + ' to ' + CAST((@oldQuantity - @Quantity) AS NVARCHAR(10)) + ' (' + IIF(@ActualDifference > 0, '+', '') + CAST(@ActualDifference AS NVARCHAR(10)) + ') for order ' + CAST(@OrderNo AS NVARCHAR(50))

		-- Deduct from ProductQuantities (includes its own stock check + InventoryLogs entry)
		EXEC dbo.DeductProductSaleableQuantity @TenantId = @TenantId
			,@UserId = @UserId
			,@ProductId = @ProductId
			,@OrderNo = @OrderNo
			,@Quantity = @Quantity
			,@Description = @LogDescription
			,@Result = @DeductResult OUTPUT

		IF @DeductResult = - 1
		BEGIN
			SET @Message = 'Product quantities cannot go negative for some records.';
			SET @ReturnStatus = 0;
			SET @ReturnMessage = @Message;

			RETURN;
		END

		IF (@IsAutoManufacture = 1 AND @OrderStatus = 3)
		BEGIN
			-- Manage RawMaterial Quantity  
			SELECT @rawMaterialSubjectTypeId = SubjectTypeId
			FROM SubjectTypes WITH (NOLOCK)
			WHERE SubjectTypeName = 'RawMaterialInventory'
				AND TenantId = @TenantId
				AND IsDeleted = 0;

			DECLARE @RawMaterialInventoryId INT;
			DECLARE @QuantityNeeded NUMERIC(18, 2);

			CREATE TABLE #TempProductMaterial (
				Id INT IDENTITY
				,ProductId BIGINT
				,QuantityNeeded NUMERIC(18, 2)
				);

			INSERT INTO #TempProductMaterial (
				ProductId
				,QuantityNeeded
				)
			SELECT rm.RawMaterialInventoryId AS ProductId
				,SUM(pm.Qty * @UpdatedQuantity) AS QuantityNeeded
			FROM ProductMaterials pm WITH (NOLOCK)
			INNER JOIN OrderSetItems osi WITH (NOLOCK) ON pm.ProductId = osi.SubjectId
				AND OSI.OrderSetItemId = @OrderSetItemId
			INNER JOIN RawMaterialInventory rm WITH (NOLOCK) ON pm.SubjectId = rm.RawMaterialId
			WHERE osi.OrderId = @OrderId
				AND osi.IsDeleted = 0
			GROUP BY rm.RawMaterialInventoryId;

			DECLARE @RawIndex INT = 1;
			DECLARE @RawCount INT = (
					SELECT MAX(Id)
					FROM #TempProductMaterial
					);

			WHILE @RawIndex <= ISNULL(@RawCount, 0)
			BEGIN
				SELECT @RawMaterialInventoryId = ProductId
					,@QuantityNeeded = QuantityNeeded
				FROM #TempProductMaterial
				WHERE Id = @RawIndex;

				SELECT @oldQuantity = pq.Inventory
				FROM RawMaterialInventory pq WITH (NOLOCK)
				WHERE pq.RawMaterialInventoryId = @RawMaterialInventoryId;

				IF @CheckRawMaterialStock = 1
				BEGIN
					SELECT @StockAvailable = (
							SELECT COUNT(*)
							FROM RawMaterialInventory WITH (NOLOCK)
							WHERE RawMaterialInventoryId = @RawMaterialInventoryId
								AND (Inventory - @QuantityNeeded >= 0)
							);

					IF @StockAvailable = 0
					BEGIN
						SET @Message = 'RawMaterials quantities cannot go negative for some records.';
						SET @ReturnStatus = 0;
						SET @ReturnMessage = @Message;

						RETURN;
					END
				END

				UPDATE RawMaterialInventory
				SET Inventory = Inventory - @QuantityNeeded
					,LastModifiedBy = @UserId
					,LastModifiedDate = SYSDATETIMEOFFSET()
					,LastModifiedUTCDate = GETUTCDATE()
				WHERE RawMaterialInventoryId = @RawMaterialInventoryId;

				SET @LogDescription = 'RawMaterial Inventory has been updated from ' + CAST(@oldQuantity AS NVARCHAR(10)) + ' to ' + CAST((@oldQuantity - @QuantityNeeded) AS NVARCHAR(10)) + ' (' + IIF((0 - @QuantityNeeded) > 0, '+', '') + CAST((0 - @QuantityNeeded) AS NVARCHAR(10)) + ') 
	            for order ' + CAST(@OrderNo AS NVARCHAR(50))

				EXEC dbo.SaveActivityLog @SubjectTypeId = @rawMaterialSubjectTypeId
					,@SubjectId = @RawMaterialInventoryId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @DT
					,@CreatedUTCDate = @DTUTC;

				SET @RawIndex = @RawIndex + 1;
			END
		END

		IF @OrderStatus = 3
			AND EXISTS (
				SELECT 1
				FROM OrderSetItems WITH (NOLOCK)
				WHERE DeliveryNo IS NULL
					AND OrderSetItemId = @OrderSetItemId
				)
		BEGIN
			SELECT @IsManufacturing = tc.IsManufacturing
			FROM TenantConfigurations tc WITH (NOLOCK)
			WHERE tc.TenantId = @TenantId;

			WITH cte
			AS (
				SELECT OrderSetItemID
					,DeliveryNo = CONCAT (
						@OrderNo
						,'_'
						,CAST(@LastSeq AS VARCHAR(256))
						)
					,ItemStatus = CASE 
						WHEN ISNULL(c.IsManufacturing, 0) = 1
							THEN 0 --Manufacture
						ELSE 2 --Ready To Deliver
						END
				FROM OrderSetItems osi WITH (NOLOCK)
				LEFT JOIN Products p WITH (NOLOCK) ON p.ProductId = OSI.SubjectId
					AND OSI.SubjectTypeId = @productSubjectTypeId
				LEFT JOIN Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
				LEFT JOIN Fabrics FB WITH (NOLOCK) ON FB.FabricId = OSI.SubjectId
					AND OSI.SubjectTypeId = @FabricSubjectTypeId
				WHERE OrderId = @OrderId
					AND osi.IsDeleted = 0
					AND osi.OrderSetItemId = @OrderSetItemId
				)
			UPDATE osi
			SET DeliveryNo = c.DeliveryNo
				,ItemStatus = c.ItemStatus
			FROM OrderSetItems osi
			INNER JOIN cte c ON c.OrderSetItemID = osi.OrderSetItemId
			WHERE osi.OrderSetItemId = @OrderSetItemId

			IF @IsManufacturing = 1
			BEGIN
				EXEC ProcessManufacturingProducts @OrderId = @OrderId
					,@TenantId = @TenantId
					,@UserId = @UserId
					,@AutoProcess = @IsAutoManufacture
					,@RequestProcessOrder = NULL
					--,@Status = @OutputStatus OUTPUT
					--,@Message = @Message OUTPUT
					--,@Error = @Error OUTPUT

				IF @IsAutoManufacture = 0  -- Manual work order flow
				BEGIN
                    EXEC CreateManufacturingWorkOrders @OrderId = @OrderId, @TenantId = @TenantId, @UserId = @UserId;
                END
			END
		END

		IF @Status IS NULL
			OR @Status = 1
		BEGIN
			SET @Status = 1;

			SELECT @JsonObject = (
					SELECT *
					FROM Orders WITH (NOLOCK)
					WHERE OrderId = @OrderId
					FOR JSON AUTO
					);

			SET @Message = 'Your order has been successfully Approved.';
			SET @Error = NULL;
			SET @ReturnStatus = @Status;
			SET @ReturnMessage = @Message;
		END
	END TRY

	BEGIN CATCH
		-- Decide rollback action depending on ownership and XACT_STATE
		SET @Status = 0;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT @JsonObject = (
				SELECT *
				FROM Orders WITH (NOLOCK)
				WHERE OrderId = @OrderId
				FOR JSON AUTO
				);

		IF @Message IS NULL
			SET @Message = 'Your order could not be Approved.';

		IF @Error IS NULL
			SET @Error = ERROR_MESSAGE();
		SET @ReturnStatus = @Status;
		SET @ReturnMessage = @Error;

		RETURN;
	END CATCH
END;

GO

