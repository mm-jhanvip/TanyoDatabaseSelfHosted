
CREATE PROCEDURE [dbo].[UpdatePOToPending]
    @POProductId INT,
    @UserID INT,
    @TenantId INT,
    @ReturnMessage NVARCHAR(100) = '' OUTPUT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE 
            @VendorOrderID INT,
            @VendorOrderSetItemId INT,
            @UpdatedDate DATETIME,
            @UpdatedUTCDate DATETIME,
            @ProductSubjectTypeId INT,
            @OrderSubjectTypeId INT,
            @PONumber VARCHAR(20),
            @Desc NVARCHAR(255),
            @Message NVARCHAR(255),
			@OrderTenantId BIGINT;

        SET @UpdatedDate = GETDATE();
        SET @UpdatedUTCDate = GETUTCDATE();

        -- Retrieve PO Product & Item Details
        SELECT TOP 1
            @VendorOrderID = p.VendorOrderId,
            @TenantId = ISNULL(@TenantId, p.TenantId), 
            @PONumber = p.PONumber,
            @VendorOrderSetItemId = PPI.VendorOrderSetItemId
        FROM POProducts p WITH (NOLOCK)  
        INNER JOIN POProductItems PPI WITH (NOLOCK) ON p.POProductId = PPI.POProductId
        WHERE p.POProductId = @POProductId;

        -- Validate PO Product Status
        IF NOT EXISTS (
            SELECT 1
            FROM POProducts WITH (NOLOCK)
            WHERE STATUS IN (2, 5)
              AND POProductId = @POProductId
              AND TenantId = @TenantId
        )
        BEGIN 
            SET @ReturnMessage = 'Operation is allowed only when the PO Product status is Approved or Material Received.';
            RETURN;
        END

        -- Fetch Product Subject Type ID
        SELECT @ProductSubjectTypeId = SubjectTypeId
        FROM SubjectTypes WITH (NOLOCK)
        WHERE TenantId = @TenantId AND SubjectTypeName = 'Products';

        BEGIN TRANSACTION;

            UPDATE POProducts
            SET STATUS = 1,
                UpdatedBy = @UserID,
                UpdatedDate = @UpdatedDate,
                UpdatedUTCDate = @UpdatedUTCDate,
                TentativePOPickupDate = NULL
            WHERE POProductId = @POProductId
              AND TenantId = @TenantId;

            UPDATE POProductItems
            SET STATUS = 1,
                UpdatedBy = @UserID,
                UpdatedDate = @UpdatedDate,
                UpdatedUTCDate = @UpdatedUTCDate,
                TentativePOItemPickupDate = NULL
            WHERE POProductId = @POProductId;

            SET @Desc = CONCAT('Purchase Order (PONumber: ', @PONumber, ') status has been changed to Pending.');

            EXEC dbo.SaveActivityLog
                @SubjectTypeId  = @ProductSubjectTypeId,
                @SubjectId      = @POProductId,
                @Description    = @Desc,
                @Action         = 'Update',
                @CreatedBy      = @UserID,
                @CreatedDate    = @UpdatedDate,
                @CreatedUTCDate = @UpdatedUTCDate;

            IF @VendorOrderID IS NOT NULL
            BEGIN

				SELECT @OrderTenantId = TenantId
                FROM Orders WITH (NOLOCK)
                WHERE OrderId = @VendorOrderID;

                SELECT @OrderSubjectTypeId = SubjectTypeId
                FROM SubjectTypes WITH (NOLOCK)
                WHERE TenantId = @OrderTenantId AND SubjectTypeName = 'Orders';

                UPDATE Orders
                SET STATUS = 9,
                    UpdatedBy = @UserID,
                    UpdatedDate = @UpdatedDate,
                    UpdatedUTCDate = @UpdatedUTCDate
                WHERE OrderId = @VendorOrderID
                  AND TenantId = @TenantId;

                UPDATE OrderSetItems
                SET IsDeleted = 1,
                    UpdatedBy = @UserID,
                    UpdatedDate = @UpdatedDate,
                    UpdatedUTCDate = @UpdatedUTCDate
                WHERE OrderId = @VendorOrderID
                  AND (@VendorOrderSetItemId IS NULL OR OrderSetItemId = @VendorOrderSetItemId);

                SET @Desc = CONCAT('The dealer has moved the Purchase Order (PONumber: ', @PONumber, ') to pending, so the order has been cancelled.');

                EXEC dbo.SaveActivityLog
                    @SubjectTypeId  = @OrderSubjectTypeId,
                    @SubjectId      = @VendorOrderID,
                    @Description    = @Desc,
                    @Action         = 'Update',
                    @CreatedBy      = @UserID,
                    @CreatedDate    = @UpdatedDate,
                    @CreatedUTCDate = @UpdatedUTCDate;
            END;

            SET @Message = CONCAT('PO Number ', @PONumber, ' status has been changed to pending.');
            
            SELECT 1 AS STATUS, @Message AS Message;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ObjectName VARCHAR(500),
                @ErrorMsg VARCHAR(MAX);

        SET @ObjectName = OBJECT_NAME(@@PROCID);
        SET @ErrorMsg = ERROR_MESSAGE();

        EXEC dbo.SaveDBErrorLog 
            @ObjectName = @ObjectName,
            @ErrorMsg = @ErrorMsg;

        THROW;
    END CATCH
END;

GO

