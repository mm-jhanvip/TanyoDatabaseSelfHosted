CREATE PROCEDURE [dbo].[UpdateProductQuantityByWarehouse] (
    @ProductQuantityByWarehouseId BIGINT,
    @Quantity DECIMAL(18, 4),
    @Remarks NVARCHAR(1000),
    @UserId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @ProductId BIGINT
               ,@WarehouseId BIGINT
               ,@OldQuantity DECIMAL(18, 4)
               ,@ProductName NVARCHAR(500)
               ,@WarehouseName NVARCHAR(250)
               ,@DateNow DATETIMEOFFSET = SYSDATETIMEOFFSET()
			   ,@DateUtcNow DATETIME = GETUTCDATE();


        SELECT 
             @OldQuantity = pqw.Quantity
            ,@WarehouseId = pqw.WarehouseId
            ,@WarehouseName = ISNULL(w.Name, '')
            ,@ProductId = pq.ProductId
            ,@ProductName = p.ProductTitle
        FROM dbo.ProductQuantitiesByWarehouse pqw WITH (NOLOCK)
        INNER JOIN dbo.Products p WITH (NOLOCK) ON pqw.ProductId = p.ProductId
        INNER JOIN dbo.ProductQuantities pq WITH (NOLOCK) ON pqw.ProductId = pq.ProductId
        LEFT JOIN dbo.Warehouse w WITH (NOLOCK) ON pqw.WarehouseId = w.Id
        WHERE pqw.ProductQuantityByWarehouseId = @ProductQuantityByWarehouseId;

        -- Begin Transaction
        BEGIN TRANSACTION UpdatePWQTran;

        -- 2. Update the Warehouse Quantity
        UPDATE dbo.ProductQuantitiesByWarehouse
        SET Quantity = @Quantity
            ,LastModifiedBy = @UserId
            ,LastModifiedDate = @DateNow
            ,LastModifiedUTCDate = @DateUtcNow
        WHERE ProductQuantityByWarehouseId = @ProductQuantityByWarehouseId;

        -- 3. Insert into InventoryLogs
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
            ,@WarehouseId
            ,ISNULL(@WarehouseName, '') 
            + ' Warehouse inventory has been replaced from ' 
            + CAST(ISNULL(TRY_CAST(@OldQuantity AS NUMERIC(18, 2)), 0) AS VARCHAR(50)) 
            + ' to ' 
            + CAST(ISNULL(TRY_CAST(@Quantity AS NUMERIC(18, 2)), 0) AS VARCHAR(50))
            + ' for ' 
            + ISNULL(@ProductName, '')
            ,@Remarks
            ,@UserId
            ,@DateNow
            ,@DateUtcNow
        );

        COMMIT TRANSACTION UpdatePWQTran;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION UpdatePWQTran;

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

