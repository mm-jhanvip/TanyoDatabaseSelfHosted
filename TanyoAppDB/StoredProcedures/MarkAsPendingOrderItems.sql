/*
EXEC MarkAsPendingOrderItems
    @TenantId = 2
    ,@UserId = 4279
    ,@PendingItemList = '1001,1002,1003'
*/
CREATE PROCEDURE [dbo].[MarkAsPendingOrderItems]
(
      @TenantId BIGINT
    , @UserId BIGINT
    , @PendingItemList VARCHAR(MAX)
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRAN MarkAsPendingOrderItems;

        ------------------------------------------------------------
        -- Validation
        ------------------------------------------------------------
        IF ISNULL(LTRIM(RTRIM(@PendingItemList)), '') = ''
        BEGIN
            SELECT
                CAST(0 AS BIT) AS Status,
                'Please select at least one product.' AS Message;

            ROLLBACK TRAN;
            RETURN;
        END

        ------------------------------------------------------------
        -- Subject Type
        ------------------------------------------------------------
        DECLARE @OrderSubjectTypeId INT;
        DECLARE @DT DATETIMEOFFSET = SYSDATETIMEOFFSET();
        DECLARE @DTUTC DATETIME = GETUTCDATE();

        SELECT @OrderSubjectTypeId = SubjectTypeId
        FROM SubjectTypes WITH (NOLOCK)
        WHERE TenantId = @TenantId
            AND SubjectTypeName = 'Orders';

        ------------------------------------------------------------
        -- Temp Table
        ------------------------------------------------------------
        CREATE TABLE #OrderSetItems
        (
            OrderSetItemId BIGINT PRIMARY KEY
        );

        INSERT INTO #OrderSetItems (OrderSetItemId)
        SELECT DISTINCT TRY_CAST(value AS BIGINT)
        FROM STRING_SPLIT(@PendingItemList, ',')
        WHERE TRY_CAST(value AS BIGINT) IS NOT NULL;

        ------------------------------------------------------------
        -- Update OrderSetItems
        ------------------------------------------------------------
        UPDATE OSI
        SET
            ItemStatus = 4 -- Pending
            , UpdatedBy = @UserId
            , UpdatedDate = SYSDATETIMEOFFSET()
            , UpdatedUTCDate = GETUTCDATE()
        FROM OrderSetItems OSI WITH (NOLOCK)
        INNER JOIN #OrderSetItems T
            ON T.OrderSetItemId = OSI.OrderSetItemId;

        ------------------------------------------------------------
        -- Order Activity Logs
        ------------------------------------------------------------
        DECLARE @Inc INT = 1;
        DECLARE @Cnt INT;
        DECLARE @SubjectId BIGINT;
        DECLARE @Description VARCHAR(MAX);
        CREATE TABLE #ActivityLogData
        (
            RowId       INT IDENTITY(1,1),
            SubjectId   BIGINT,
            Description VARCHAR(MAX)
        );
        INSERT INTO #ActivityLogData (SubjectId, Description)
        SELECT
              OSI.OrderId
            , 'Product ' + ISNULL(P.ProductTitle, '') + ' has been Pending.'
        FROM OrderSetItems OSI WITH (NOLOCK)
        INNER JOIN #OrderSetItems T
            ON T.OrderSetItemId = OSI.OrderSetItemId
        INNER JOIN Products P WITH (NOLOCK)
            ON P.ProductId = OSI.SubjectId;
        SELECT @Cnt = COUNT(1) FROM #ActivityLogData;

        WHILE @Cnt >= @Inc
        BEGIN
            SELECT @SubjectId   = SubjectId,
                   @Description = Description
            FROM #ActivityLogData
            WHERE RowId = @Inc;

            EXEC dbo.SaveActivityLog
                @SubjectTypeId  = @OrderSubjectTypeId,
                @SubjectId      = @SubjectId,
                @Description    = @Description,
                @Action         = 'UPDATE',
                @CreatedBy      = @UserId,
                @CreatedDate    = @DT,
                @CreatedUTCDate = @DTUTC;
            SET @Inc = @Inc + 1;
        END;

        DROP TABLE #ActivityLogData;

        ------------------------------------------------------------
        -- Success
        ------------------------------------------------------------
        COMMIT TRAN MarkAsPendingOrderItems;

        SELECT
            CAST(1 AS BIT) AS Status,
            'Products marked as Pending successfully.' AS Message;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN MarkAsPendingOrderItems;

        DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

        SELECT
            CAST(0 AS BIT) AS Status,
            ERROR_MESSAGE() AS Message;

    END CATCH
END

GO

