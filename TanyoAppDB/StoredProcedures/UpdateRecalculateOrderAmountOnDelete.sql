CREATE   PROCEDURE [dbo].[UpdateRecalculateOrderAmountOnDelete]
(
    @OrderId BIGINT
    ,@TenantId INT
    ,@UserId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ----------------------------------------------------------
        -- Validate Order
        ----------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM Orders o WITH (NOLOCK)
            WHERE o.OrderId = @OrderId
            AND o.TenantId = @TenantId
            AND o.Status IN (9) --Delivered
        )
        BEGIN
            RAISERROR('Order has been Delivered', 16, 1)
            RETURN
        END

        ----------------------------------------------------------
        -- Get Order Information
        ----------------------------------------------------------
        DECLARE @GSTType BIT
            ,@OrderNo VARCHAR(50)

        SELECT @GSTType = o.GSTType
            ,@OrderNo = o.OrderNo
        FROM Orders o WITH (NOLOCK)
        WHERE o.OrderId = @OrderId

        ----------------------------------------------------------
        -- Subject Type IDs
        ----------------------------------------------------------
        DECLARE @ProductSubjectTypeId BIGINT
            ,@FabricSubjectTypeId BIGINT
            ,@PolishSubjectTypeId BIGINT

        SELECT @ProductSubjectTypeId = SubjectTypeId
        FROM SubjectTypes st WITH (NOLOCK)
        WHERE st.SubjectTypeName = 'Products'
        AND st.TenantId = @TenantId

        SELECT @FabricSubjectTypeId = SubjectTypeId
        FROM SubjectTypes st WITH (NOLOCK)
        WHERE st.SubjectTypeName = 'Fabrics'
        AND st.TenantId = @TenantId

        SELECT @PolishSubjectTypeId = SubjectTypeId
        FROM SubjectTypes st WITH (NOLOCK)
        WHERE st.SubjectTypeName = 'Polish'
        AND st.TenantId = @TenantId

        ----------------------------------------------------------
        -- Update GST in OrderSetItems
        ----------------------------------------------------------
        EXEC [dbo].[RefreshInquiry]
            @RefreshInquiry = 1
			,@OrderID = @OrderId
			,@ProductSubjectTypeId = @ProductSubjectTypeId
			,@FabricSubjectTypeId = @FabricSubjectTypeId
			,@PolishSubjectTypeId = @PolishSubjectTypeId

        ----------------------------------------------------------
        -- Update TotalAmount in OrderSetItems
        ----------------------------------------------------------
        UPDATE osi
        SET osi.TotalAmount = CAST(ROUND(((osi.UnitPrice * (100 - osi.DiscountPrice)) / 100.0), 2) * osi.Quantity AS NUMERIC(18, 0))
        FROM OrderSetItems osi
        WHERE osi.OrderId = @OrderId
        AND osi.IsDeleted = 0

        ----------------------------------------------------------
        -- Update OrderSetItems and Order
        ----------------------------------------------------------
        EXEC [dbo].[UpdateOrderGST]
            @OrderID = @OrderId
            ,@GSTType = @GSTType
            ,@UserID = @UserId
            ,@TenantID = @TenantId
        
    END TRY
    BEGIN CATCH
        DECLARE
              @ErrorMessage NVARCHAR(4000)
            ,@ErrorSeverity INT
            ,@ErrorState INT;

        SELECT
              @ErrorMessage = ERROR_MESSAGE()
            ,@ErrorSeverity = ERROR_SEVERITY()
            ,@ErrorState = ERROR_STATE();

        DECLARE @ObjectName VARCHAR(500)
		SET @ObjectName = OBJECT_NAME(@@PROCID)
		
		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

GO

