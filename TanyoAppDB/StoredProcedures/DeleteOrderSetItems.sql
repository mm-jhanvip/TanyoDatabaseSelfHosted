/*    
 EXEC [dbo].[DeleteOrderSetItems]
  @OrderSetItemId = 757
  ,@DeletedBy = 4279
  ,@TenantId = 2
*/
CREATE PROCEDURE [dbo].[DeleteOrderSetItems] (
 @OrderSetItemId BIGINT
 ,@DeletedBy BIGINT
 ,@TenantId INT
 )
WITH ENCRYPTION
AS
BEGIN
 SET NOCOUNT ON;

 DECLARE @Status INT
  ,@Message VARCHAR(200)
  ,@OrderId BIGINT
  ,@SubjectTypeId INT
  ,@ItemType VARCHAR(50)
  ,@ProductName VARCHAR(150)
  ,@OrderStatus INT
  ,@IsQuantityOnHold BIT
  ,@cnt INT
  ,@ID INT = 1
  ,@UpdateOrdersetItemId BIGINT
  ,@dtoffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
  ,@dtutc DATETIME = GETUTCDATE()
  ,@ActivityDescription VARCHAR(MAX);

 BEGIN TRY
  SELECT @OrderId = OrderId
  FROM OrderSetItems WITH (NOLOCK)
  WHERE OrderSetItemId = @OrderSetItemId

  IF (
    SELECT COUNT(1)
    FROM OrderSetItems osi 
    WHERE osi.OrderId = @OrderId
     AND osi.IsDeleted = 0
    ) = 1
  BEGIN
   SET @Status = - 1
   SET @Message = 'You cannot delete the last item as it is the last item in the order.'

   SELECT @Status AS [Status]
    ,@Message AS [Message]
    ,NULL AS [Data]
    ,@Message AS [Error]

   RETURN
  END

  IF EXISTS (
    SELECT 1
    FROM OrderSetItems osi
    INNER JOIN Orders o ON o.OrderId = osi.OrderId
    WHERE o.OrderId = @OrderId
     AND osi.OrderSetItemId = @orderSetItemId
     AND osi.IsDeleted = 0
     AND osi.ItemSTATUS = 3 --Delivered
    )
  BEGIN
   SET @Status = - 1
   SET @Message = 'You cannot delete the item from Delivered order.'

   SELECT @Status AS [Status]
    ,@Message AS [Message]
    ,NULL AS [Data]
    ,@Message AS [Error]

   RETURN
  END

  BEGIN TRANSACTION DeleteOrderSetItems

  DROP TABLE

  IF EXISTS #AddOnSetItems;
   SELECT @ItemType = st.SubjectTypeName
    ,@ProductName = ISNULL(p.ProductTitle, f.Title)
    ,@OrderId = osi.OrderId
    ,@IsQuantityOnHold = IsQuantityOnHold
   FROM OrderSetItems osi WITH (NOLOCK)
   LEFT JOIN SubjectTypes st WITH (NOLOCK) ON st.SubjectTypeId = osi.SubjectTypeId
    AND st.TenantId = @TenantId
   LEFT JOIN Products p WITH (NOLOCK) ON p.ProductId = osi.SubjectId
    AND p.TenantId = @TenantId
   LEFT JOIN Fabrics f WITH (NOLOCK) ON f.FabricId = osi.SubjectId
    AND f.TenantId = @TenantId
   WHERE osi.OrderSetItemId = @OrderSetItemId

  SELECT OrderSetItemId
   ,ROW_NUMBER() OVER (
    ORDER BY OrderSetItemId
    ) AS RowNum
  INTO #AddOnSetItems
  FROM OrderSetItems WITH (NOLOCK)
  WHERE ParentOrderSetItemId = @OrderSetItemId

  SELECT @OrderStatus = STATUS
  FROM Orders WITH (NOLOCK)
  WHERE OrderId = @OrderId

  -- 2. Get SubjectTypeId for 'Orders'  
  SELECT @SubjectTypeId = SubjectTypeId
  FROM SubjectTypes WITH (NOLOCK)
  WHERE SubjectTypeName = 'Orders'
   AND TenantId = @TenantId
   AND IsDeleted = 0

  IF EXISTS (
    SELECT 1
    FROM StockOnHold soh WITH (NOLOCK)
    INNER JOIN #AddOnSetItems AOSI ON SOH.OrderSetItemId = AOSI.OrderSetItemId
    INNER JOIN OrderSetItems OSI ON OSI.OrderSetItemId = AOSI.OrderSetItemId
    WHERE soh.IsStockOnHold = 1
     AND OSI.IsQuantityOnHold = 1
    )
  BEGIN
   SET @ID = 1

   SELECT @cnt = count(OrderSetItemId)
   FROM #AddOnSetItems

   WHILE @ID <= @cnt
   BEGIN
    SELECT @UpdateOrdersetItemId = OrderSetItemId
    FROM #AddOnSetItems
    WHERE RowNum = @ID

    EXEC [dbo].[ReleaseStockOnHoldByOrderSetItemId] @OrderSetItemId = @UpdateOrdersetItemId
     ,@OrderId = @OrderId
     ,@UserId = @DeletedBy

    SET @ID = @ID + 1
   END
  END

  IF EXISTS (
    SELECT 1
    FROM #AddOnSetItems
    )
  BEGIN
   DELETE OPC
   FROM OrderProductCharges OPC
   INNER JOIN #AddOnSetItems AOSI ON OPC.OrderSetItemId = AOSI.OrderSetItemId
   WHERE OPC.OrderId = @OrderId

   DELETE OMF
   FROM OrderManufacturingWorkflows OMF
   INNER JOIN #AddOnSetItems AOSI ON OMF.OrderSetItemId = AOSI.OrderSetItemId
   WHERE OMF.OrderId = @OrderId

   DELETE OSIR
   FROM OrderSetItemReceivables OSIR
   INNER JOIN #AddOnSetItems AOSI ON OSIR.OrderSetItemId = AOSI.OrderSetItemId

   DELETE ORDD
   FROM OrderDeliveryDetails ORDD
   INNER JOIN #AddOnSetItems AOSI ON ORDD.OrderSetItemId = AOSI.OrderSetItemId
   WHERE ORDD.OrderId = @OrderId

   DELETE OSITM
   FROM OrderSetItemImages OSITM
   INNER JOIN #AddOnSetItems AOSI ON OSITM.OrderSetItemId = AOSI.OrderSetItemId

   DELETE SOKH
   FROM StockOnHold SOKH
   INNER JOIN #AddOnSetItems AOSI ON SOKH.OrderSetItemId = AOSI.OrderSetItemId
   WHERE SOKH.OrderId = @OrderId

   UPDATE INDE
   SET OrderSetItemId = NULL
   FROM InwardDetailsEntry INDE
   INNER JOIN #AddOnSetItems AOSI ON INDE.OrderSetItemId = AOSI.OrderSetItemId

   DELETE CS
   FROM Complains CS
   INNER JOIN #AddOnSetItems AOSI ON CS.OrderSetItemId = AOSI.OrderSetItemId
   WHERE CS.OrderId = @OrderId

   DELETE WCL
   FROM WhatsAppComplaintLogs WCL
   INNER JOIN #AddOnSetItems AOSI ON WCL.OrderSetItemId = AOSI.OrderSetItemId
   WHERE WCL.OrderId = @OrderId
  END

  IF EXISTS (
    SELECT 1
    FROM OrderSetItems osi WITH (NOLOCK)
    INNER JOIN StockOnHold soh WITH (NOLOCK) ON soh.OrderSetItemId = osi.OrderSetItemId
     AND soh.IsStockOnHold = 1
    WHERE osi.OrderSetItemId = @OrderSetItemId
     AND osi.OrderId = @OrderId
    )
  BEGIN
   EXEC [dbo].[ReleaseStockOnHoldByOrderSetItemId] @OrderSetItemId = @OrderSetItemId
    ,@OrderId = @OrderId
    ,@UserId = @DeletedBy
  END

  -- 3. Delete Charges  
  DELETE
  FROM OrderProductCharges
  WHERE OrderSetItemId = @OrderSetItemId
   AND OrderId = @OrderId

  DELETE OMWF
  FROM OrderManufacturingWorkflows OMWF
  WHERE OMWF.OrderSetItemId = @OrderSetItemId
   AND OMWF.OrderId = @OrderId

  DELETE OSR
  FROM OrderSetItemReceivables OSR
  WHERE OSR.OrderSetItemId = @OrderSetItemId

  DELETE ODD
  FROM OrderDeliveryDetails ODD
  WHERE ODD.OrderSetItemId = @OrderSetItemId
   AND ODD.OrderId = @OrderId

  DELETE OSIM
  FROM OrderSetItemImages OSIM
  WHERE OSIM.OrderSetItemId = @OrderSetItemId

  DELETE SOH
  FROM StockOnHold SOH
  WHERE SOH.OrderSetItemId = @OrderSetItemId
   AND SOH.OrderId = @OrderId

  UPDATE IDE
  SET OrderSetItemId = NULL
  FROM InwardDetailsEntry IDE
  WHERE IDE.OrderSetItemId = @OrderSetItemId

  DELETE C
  FROM Complains C
  WHERE C.OrderSetItemId = @OrderSetItemId
   AND C.OrderId = @OrderId

  DELETE WC
  FROM WhatsAppComplaintLogs WC
  WHERE WC.OrderSetItemId = @OrderSetItemId
   AND WC.OrderId = @OrderId

  -- 4. Mark related OrderSetItems as deleted (both parent and child)  
  --UPDATE OrderSetItems
  --SET IsDeleted = 1
  -- ,UpdatedDate = GETDATE()
  -- ,UpdatedUTCDate = GETUTCDATE()
  --WHERE OrderSetItemId = @OrderSetItemId
  -- OR ParentOrderSetItemId = @OrderSetItemId
  IF @OrderStatus >= 2
   AND @OrderStatus NOT IN (
    5
    ,8
    ) --Delivered, Declined
  BEGIN
   DROP TABLE IF EXISTS #InventoryResult;

   CREATE TABLE #InventoryResult
   (
    Status BIT
    ,Message NVARCHAR(MAX)
    ,Data NVARCHAR(MAX)
    ,Error NVARCHAR(MAX)
   )

   -- 5. Update Inventory
   INSERT INTO #InventoryResult
   (
    Status
    ,Message
    ,Data
    ,Error
   )
   EXEC UpdateInventoryByOrderSetItem @OrderId = @OrderId
    ,@OrderSetItemId = @OrderSetItemId
    ,@TenantId = @TenantId
    ,@UserId = @DeletedBy
  END   

  -- 7. Log Activity  
  SELECT @ActivityDescription = ISNULL(@ItemType, '') + ' ' + ISNULL(@ProductName, '') + ' has been deleted.';

  EXEC dbo.SaveActivityLog @SubjectTypeId = @SubjectTypeId
   ,@SubjectId = @OrderId
   ,@Description = @ActivityDescription
   ,@Action = 'DELETE'
   ,@CreatedBy = @DeletedBy
   ,@CreatedDate = @dtoffset
   ,@CreatedUTCDate = @dtutc;

  DELETE OSI
  FROM OrderSetItems OSI
  WHERE OSI.OrderSetItemId = @OrderSetItemId
   OR OSI.ParentOrderSetItemId = @OrderSetItemId

  IF EXISTS (
    SELECT 1
    FROM OrderSetItems
    WHERE OrderId = @OrderId
    )
   AND NOT EXISTS (
    SELECT 1
    FROM OrderSetItems
    WHERE OrderId = @OrderId
     AND ItemStatus <> 3
    )
  BEGIN
   UPDATE Orders
   SET STATUS = 5
    ,UpdatedBy = @DeletedBy
    ,UpdatedDate = GETDATE()
    ,UpdatedUTCDate = GETUTCDATE()
   WHERE OrderId = @OrderId
    AND STATUS <> 5;

   IF @@ROWCOUNT > 0
   BEGIN
    EXEC dbo.SaveActivityLog @SubjectTypeId = @SubjectTypeId
     ,@SubjectId = @OrderId
     ,@Description = 'Inquiry status has been changed to Delivered.'
     ,@Action = 'UPDATE'
     ,@CreatedBy = @DeletedBy
     ,@CreatedDate = @dtoffset
     ,@CreatedUTCDate = @dtutc;
   END
  END

  COMMIT TRANSACTION DeleteOrderSetItems

  -- Success response  
  SET @Status = 1
  SET @Message = 'The deletion of your order set item was successful.'

  SELECT @Status AS [Status]
   ,@Message AS [Message]
   ,NULL AS [Data]
   ,NULL AS [Error]

  -- Recalculate Order Amount after delete order set item
  EXEC dbo.UpdateOrderRefreshInquiry @OrderId = @OrderId
   ,@TenantId = @TenantId
   ,@UserId = @DeletedBy
   --EXEC UpdateRecalculateOrderAmountOnDelete
   -- @OrderId = @OrderId
   -- ,@TenantId = @TenantId
   -- ,@UserId = @DeletedBy
 END TRY

 BEGIN CATCH
  IF @@TRANCOUNT > 0
   ROLLBACK TRANSACTION DeleteOrderSetItems

  SET @Status = 0
  SET @Message = 'The deletion of your order set item was unsuccessful.'

  DECLARE @ObjectName VARCHAR(500)
   ,@ErrorMsg VARCHAR(MAX)

  SET @ObjectName = OBJECT_NAME(@@PROCID)
  SET @ErrorMsg = ERROR_MESSAGE()

  EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
   ,@ErrorMsg = @ErrorMsg

  SELECT @Status AS [Status]
   ,@Message AS [Message]
   ,NULL AS [Data]
   ,@ErrorMsg AS [Error]
 END CATCH
END

GO

