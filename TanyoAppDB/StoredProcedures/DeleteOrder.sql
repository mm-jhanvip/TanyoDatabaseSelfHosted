/*
	EXEC [dbo].[DeleteOrder] @OrderId = 84,@DeletedBy = 1
*/
CREATE PROCEDURE [dbo].[DeleteOrder] (
	@OrderId VARCHAR(MAX)
	,@DeletedBy BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Status BIT
		,@Message VARCHAR(100)
		,@Error VARCHAR(MAX)
		,@IncOrderId BIGINT;

	DROP TABLE

	IF EXISTS #DelOrder
		DROP TABLE

	IF EXISTS #OrderList
		SELECT CAST(TRIM(ORD.value) AS BIGINT) AS OrderId
		INTO #DelOrder
		FROM STRING_SPLIT(TRIM(@OrderId), ',') ORD

	BEGIN TRY
		BEGIN TRAN delOrder

		DECLARE @SubjectTypeId BIGINT
			,@OrderNo VARCHAR(20)
			,@TenantId BIGINT
			,@OrderStatus INT;

		SELECT ORD.OrderId
			,ORD.OrderNo
			,ORD.TenantId
			,ORD.STATUS
		INTO #OrderList
		FROM Orders ORD WITH (NOLOCK)
		INNER JOIN #DelOrder DORD ON DORD.OrderId = ORD.OrderId

		SELECT TOP 1 @TenantId = TenantId
		FROM #OrderList
		ORDER BY OrderId DESC

		SELECT @SubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE TenantId = @TenantId
			AND SubjectTypeName = 'ProductQuantity'

		-- Check Stock on Hold and Release if any
		DECLARE @Temp_OrderSetItems TABLE (
			ID INT PRIMARY KEY IDENTITY
			,OrderSetItemId BIGINT
			,OrderId BIGINT
			,OrderNo VARCHAR(20)
			,SubjectId BIGINT
			,SubjectTypeId INT
			,OrderStatus INT
			)

		INSERT INTO @Temp_OrderSetItems (
			OrderSetItemId
			,OrderId
			,OrderNo
			,SubjectId
			,SubjectTypeId
			,OrderStatus
			)
		SELECT OSI.OrderSetItemId
			,OSI.OrderId
			,ORDL.OrderNo
			,OSI.SubjectId
			,OSI.SubjectTypeId
			,ORDL.STATUS
		FROM OrderSetItems OSI WITH (NOLOCK)
		INNER JOIN #OrderList ORDL ON ORDL.OrderId = OSI.OrderId

		DECLARE @OrderSetItemId BIGINT
			,@cnt INT
			,@inc INT = 1

		SELECT @cnt = COUNT(1)
		FROM @Temp_OrderSetItems

		WHILE (@cnt >= @inc)
		BEGIN
			SELECT @OrderSetItemId = NULL

			SELECT @IncOrderId = NULL

			SELECT @OrderStatus = NULL

			SELECT @OrderSetItemId = OrderSetItemId
				,@IncOrderId = OrderId
				,@OrderStatus = OrderStatus
			FROM @Temp_OrderSetItems
			WHERE ID = @inc

			IF @OrderStatus >= 2
				AND @OrderStatus NOT IN (
					5
					,8
					) --Delivered, Declined
			BEGIN
				EXEC [dbo].[UpdateInventoryByOrderSetItem] @OrderSetItemId = @OrderSetItemId
					,@OrderId = @IncOrderId
					,@UserId = @DeletedBy
					,@TenantId = @TenantId
			END

			EXEC [dbo].[ReleaseStockOnHoldByOrderSetItemId] @OrderSetItemId = @OrderSetItemId
				,@OrderId = @IncOrderId
				,@UserId = @DeletedBy

			SET @inc = @inc + 1
		END

		UPDATE al
		SET AL.Description = LEFT(Description, CASE 
					WHEN (CHARINDEX('for order', Description) - 2) >= 0
						THEN (CHARINDEX('for order', Description) - 2)
					ELSE CASE 
							WHEN (CHARINDEX('From', Description) - 2) >= 0
								THEN (CHARINDEX('From', Description) - 2)
							ELSE CASE 
									WHEN (CHARINDEX('For', Description) - 2) >= 0
										THEN (CHARINDEX('For', Description) - 2)
									ELSE (CHARINDEX(ORDL.OrderNo, Description) - 2)
									END
							END
					END)
		FROM InventoryLogs al
		INNER JOIN #OrderList ORDL ON Description LIKE '%' + ORDL.OrderNo + '%'
		WHERE al.Productid IN (
				SELECT osi.SubjectId AS Productid
				FROM @Temp_OrderSetItems osi
				INNER JOIN SubjectTypes st WITH (NOLOCK) ON st.SubjectTypeId = osi.SubjectTypeId
					AND st.SubjectTypeName = 'Products'
				)

		--INNER JOIN ProductQuantities pq WITH (NOLOCK) ON pq.ProductId = osi.SubjectId      
		UPDATE OC
		SET OC.STATUS = 9
		FROM dbo.OrderComments OC
		INNER JOIN #OrderList ORDL ON OC.OrderId = ORDL.OrderId

		UPDATE PTS
		SET IsDeleted = 1
			,UpdatedBy = @DeletedBy
			,UpdatedDate = GETDATE()
			,UpdatedUTCDate = GETUTCDATE()
		FROM dbo.Payments PTS
		INNER JOIN #OrderList ORDL ON PTS.OrderId = ORDL.OrderId

		UPDATE OSI
		SET IsDeleted = 1
			,UpdatedBy = @DeletedBy
			,UpdatedDate = GETDATE()
			,UpdatedUTCDate = GETUTCDATE()
		FROM dbo.OrderSetItems OSI
		INNER JOIN #OrderList ORDL ON OSI.OrderId = ORDL.OrderId

		UPDATE OS
		SET IsDeleted = 1
			,UpdatedBy = @DeletedBy
			,UpdatedDate = GETDATE()
			,UpdatedUTCDate = GETUTCDATE()
		FROM dbo.OrderSets OS
		INNER JOIN #OrderList ORDL ON OS.OrderId = ORDL.OrderId

		UPDATE ORD
		SET STATUS = 9
			,UpdatedBy = @DeletedBy
			,UpdatedDate = GETDATE()
			,UpdatedUTCDate = GETUTCDATE()
		FROM dbo.Orders ORD
		INNER JOIN #OrderList ORDL ON ORD.OrderId = ORDL.OrderId

		--DELETE WCL
		--FROM dbo.WhatsAppComplaintLogs WCL
		--INNER JOIN #OrderList ORDL ON WCL.OrderId = ORDL.OrderId
		--DELETE al
		--FROM ActivityLogs al
		--INNER JOIN SubjectTypes st ON st.SubjectTypeId = al.SubjectTypeId
		--	AND SubjectTypeName = 'Orders'
		--INNER JOIN #OrderList ORDL ON al.Subjectid = ORDL.OrderId
		--DELETE n
		--FROM Notifications n
		--INNER JOIN SubjectTypes st ON st.SubjectTypeId = n.EntityTypeId
		--	AND SubjectTypeName = 'Orders'
		--INNER JOIN #OrderList ORDL ON n.EntityId = ORDL.OrderId
		--DELETE nm
		--FROM NotificationManagement nm
		--INNER JOIN SubjectTypes st ON st.SubjectTypeId = nm.EntityTypeId
		--	AND SubjectTypeName = 'Orders'
		--INNER JOIN #OrderList ORDL ON nm.EntityId = ORDL.OrderId
		--DELETE 
		--FROM ComplainAttachments 
		--WHERE ComplainId IN 
		--					(
		--						SELECT ComplainId 
		--						FROM Complains CS
		--						INNER JOIN #OrderList ORDL ON CS.OrderId = ORDL.OrderId
		--					)
		--DELETE 
		--FROM ComplainComments 
		--WHERE ComplainId IN 
		--					(
		--						SELECT ComplainId 
		--						FROM Complains CS
		--						INNER JOIN #OrderList ORDL ON CS.OrderId = ORDL.OrderId
		--					)
		--DELETE CS
		--FROM dbo.Complains CS
		--INNER JOIN #OrderList ORDL ON CS.OrderId = ORDL.OrderId
		--DELETE
		--FROM dbo.PaymentGatewayLog
		--WHERE OrderId = @OrderId
		--DELETE OSU
		--FROM dbo.OrderShortedURL OSU
		--INNER JOIN #OrderList ORDL ON OSU.OrderId = ORDL.OrderId
		--DELETE FBC
		--FROM dbo.FeedbackComments FBC
		--INNER JOIN #OrderList ORDL ON FBC.OrderId = ORDL.OrderId
		--DELETE FBO
		--FROM dbo.FeedbackOrders FBO
		--INNER JOIN #OrderList ORDL ON FBO.OrderId = ORDL.OrderId
		--DELETE FORD
		--FROM dbo.FollowUpOrders FORD
		--INNER JOIN #OrderList ORDL ON FORD.OrderId = ORDL.OrderId
		--DELETE KES
		--FROM dbo.KafkaEmailSending KES
		--INNER JOIN #OrderList ORDL ON KES.OrderId = ORDL.OrderId
		--DELETE
		--FROM dbo.OfferOrderMapping
		--WHERE OrderId = @OrderId
		--DELETE OA
		--FROM dbo.OrderAddresses OA
		--INNER JOIN #OrderList ORDL ON OA.OrderId = ORDL.OrderId
		--DELETE OAV
		--FROM dbo.OrderAnonymousViews OAV
		--INNER JOIN #OrderList ORDL ON OAV.OrderId = ORDL.OrderId
		--DELETE OA
		--FROM dbo.OrderAttachments OA
		--INNER JOIN #OrderList ORDL ON OA.OrderId = ORDL.OrderId
		--DELETE OC
		--FROM dbo.OrderComments OC
		--INNER JOIN #OrderList ORDL ON OC.OrderId = ORDL.OrderId
		--DELETE PT
		--FROM dbo.Payments PT
		--INNER JOIN #OrderList ORDL ON PT.OrderId = ORDL.OrderId
		--DELETE 
		--FROM OrderSetItemReceivables 
		--WHERE OrderSetItemId IN (SELECT OrderSetItemId FROM @Temp_OrderSetItems)
		--DELETE 
		--FROM OrderSetItemImages 
		--WHERE OrderSetItemId IN (SELECT OrderSetItemId FROM @Temp_OrderSetItems )
		--DELETE AORD
		--FROM dbo.Archive_Orders AORD
		--INNER JOIN #OrderList ORDL ON AORD.OrderId = ORDL.OrderId
		--DELETE AOSI
		--FROM dbo.Archive_OrderSetItems AOSI
		--INNER JOIN #OrderList ORDL ON AOSI.OrderId = ORDL.OrderId
		--DELETE AOS
		--FROM dbo.Archive_OrderSets AOS
		--INNER JOIN #OrderList ORDL ON AOS.OrderId = ORDL.OrderId
		--DELETE 
		--FROM ManufacturingActivityLogs 
		--WHERE ManufacturingWorkflowId IN 
		--								(
		--									SELECT OrderManufacturingWorkflowId 
		--									FROM OrderManufacturingWorkflows OMWFL
		--									INNER JOIN #OrderList ORDL ON OMWFL.OrderId = ORDL.OrderId											
		--								) -- OrderManufacturingWorkflowId
		--DELETE 
		--FROM OrderManufacturingWorkflowImages 
		--WHERE OrderManufacturingWorkflowId IN 
		--										(
		--											SELECT OrderManufacturingWorkflowId 
		--											FROM OrderManufacturingWorkflows OMWFL
		--											INNER JOIN #OrderList ORDL ON OMWFL.OrderId = ORDL.OrderId											
		--										) -- OrderManufacturingWorkflowId
		--DELETE OMWFL
		--FROM dbo.OrderManufacturingWorkflows OMWFL
		--INNER JOIN #OrderList ORDL ON OMWFL.OrderId = ORDL.OrderId											
		--DELETE OPC
		--FROM dbo.OrderProductCharges OPC
		--INNER JOIN #OrderList ORDL ON OPC.OrderId = ORDL.OrderId											
		--DELETE OSI
		--FROM dbo.OrderSetItems OSI
		--INNER JOIN #OrderList ORDL ON OSI.OrderId = ORDL.OrderId											
		--DELETE OS
		--FROM dbo.OrderSets OS
		--INNER JOIN #OrderList ORDL ON OS.OrderId = ORDL.OrderId											
		--DELETE SOH
		--FROM dbo.StockOnHold SOH
		--INNER JOIN #OrderList ORDL ON SOH.OrderId = ORDL.OrderId											
		--DELETE ORD
		--FROM dbo.Orders ORD
		--INNER JOIN #OrderList ORDL ON ORD.OrderId = ORDL.OrderId
		COMMIT TRAN delOrder

		SET @Status = 1;

		SELECT @Message = 'The deletion of your order was successful.';

		SET @Error = NULL;

		SELECT @Status AS [Status]
			,@Message AS [Message]
			,NULL AS [Data]
			,@Error AS [Error]
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
		DECLARE @ErrorMsg VARCHAR(MAX)

		IF @@TRANCOUNT > 0
		BEGIN
			ROLLBACK TRAN delOrder
		END

		SET @Status = 0;

		SELECT @Message = 'The deletion of your order was unsuccessful.';

		SET @Error = NULL;
		SET @ErrorMsg = ERROR_MESSAGE()
		SET @ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT @Status AS [Status]
			,@Message AS [Message]
			,NULL AS [Data]
			,@ErrorMsg AS [Error]

		RAISERROR (
				'Error in DeleteOrder : %s'
				,15
				,1
				,@ErrorMsg
				)
	END CATCH
END

GO

