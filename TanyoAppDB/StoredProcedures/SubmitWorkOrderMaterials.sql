/*
EXEC SubmitWorkOrderMaterials
    @TenantId = 2
    ,@UserId = 4279
    ,@ManufacturingWorkOrderId = 1
    ,@ReceivedBy = 4280
    ,@JsonData = '
    [
        {"ManufacturingWorkOrderDetailId":3,"RawMaterialId":783,"ProvidedQty":2,"IsNotNeeded":false},
        {"ManufacturingWorkOrderDetailId":4,"RawMaterialId":784,"ProvidedQty":0,"IsNotNeeded":true},
        {"ManufacturingWorkOrderDetailId":0,"RawMaterialId":790,"ProvidedQty":5,"IsNotNeeded":false}
    ]'
*/
CREATE   PROCEDURE [dbo].[SubmitWorkOrderMaterials]
(
    @TenantId BIGINT,
    @UserId BIGINT,
    @ManufacturingWorkOrderId BIGINT,
    @ReceivedBy BIGINT,
    @JsonData NVARCHAR(MAX)
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN SubmitWorkOrderMaterials;

        DECLARE @DT DATETIMEOFFSET = SYSDATETIMEOFFSET();
        DECLARE @DTUTC DATETIME = GETUTCDATE();
        DECLARE @GetDT DATETIME = GETDATE();
        DECLARE @OrderNo VARCHAR(50);
        DECLARE @rawMaterialSubjectTypeId INT;
        DECLARE @CheckRawMaterialStock BIT;

        ------------------------------------------------------------
        -- Get OrderNo
        ------------------------------------------------------------
        SELECT @OrderNo = O.OrderNo
        FROM ManufacturingWorkOrders MWO
        INNER JOIN Orders O ON MWO.OrderId = O.OrderId
        WHERE MWO.ManufacturingWorkOrderId = @ManufacturingWorkOrderId;

        ------------------------------------------------------------
        -- Get SubjectTypeId
        ------------------------------------------------------------
        SELECT @rawMaterialSubjectTypeId = SubjectTypeId
        FROM SubjectTypes
        WHERE SubjectTypeName = 'RawMaterialInventory'
            AND TenantId = @TenantId
            AND IsDeleted = 0;

        SELECT @CheckRawMaterialStock = (
            SELECT CheckRawMaterialStock
            FROM Tenants
            WHERE TenantId = @TenantId
        );

        ------------------------------------------------------------
        -- Parse JSON
        ------------------------------------------------------------
        DECLARE @Temp TABLE
        (
            ManufacturingWorkOrderDetailId BIGINT,
            RawMaterialId BIGINT,
            ProvidedQty NUMERIC(18, 2),
            IsNotNeeded BIT
        );

        INSERT INTO @Temp
        (
            ManufacturingWorkOrderDetailId,
            RawMaterialId,
            ProvidedQty,
            IsNotNeeded
        )

        SELECT
            ISNULL(ManufacturingWorkOrderDetailId, 0),
            RawMaterialId,
            CASE
                WHEN ISNULL(IsNotNeeded, 0) = 1 THEN 0
                ELSE ISNULL(ProvidedQty, 0)
            END,
            ISNULL(IsNotNeeded, 0)
        FROM OPENJSON(@JsonData)
        WITH
        (
            ManufacturingWorkOrderDetailId BIGINT,
            RawMaterialId BIGINT,
            ProvidedQty NUMERIC(18, 2),
            IsNotNeeded BIT
        );

        ------------------------------------------------------------
        -- Validate duplicate raw materials in payload
        ------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM @Temp
            GROUP BY RawMaterialId
            HAVING COUNT(1) > 1
        )
        BEGIN

            ROLLBACK TRAN;

            SELECT
                CAST(0 AS BIT) AS Status,
                'Duplicate raw material selected.' AS Message;
            RETURN;
        END

        ------------------------------------------------------------
        -- Insert additional raw materials (ManufacturingWorkOrderDetailId = 0)
        ------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM @Temp T
            WHERE T.ManufacturingWorkOrderDetailId = 0
                AND EXISTS
                (
                    SELECT 1
                    FROM ManufacturingWorkOrderDetails D
                    WHERE D.ManufacturingWorkOrderId = @ManufacturingWorkOrderId
                        AND D.RawMaterialId = T.RawMaterialId
                )
        )

        BEGIN

            ROLLBACK TRAN;

            SELECT
                CAST(0 AS BIT) AS Status,
                'Raw material already exists in this work order.' AS Message;

            RETURN;
        END

        INSERT INTO ManufacturingWorkOrderDetails
        (
            ManufacturingWorkOrderId,
            RawMaterialId,
            RequiredQty,
            ProvidedQty,
            IsNotNeeded,
            IsFromBom,
            CreatedBy,
            CreatedDate,
            CreatedUTCDate
        )
        SELECT
            @ManufacturingWorkOrderId,
            T.RawMaterialId,
            NULL,
            0,
            0,
            0,
            @UserId,
            @DT,
            @DTUTC
        FROM @Temp T
        WHERE T.ManufacturingWorkOrderDetailId = 0;

        ------------------------------------------------------------
        -- Map newly inserted detail ids back to payload rows
        ------------------------------------------------------------
        UPDATE T
        SET T.ManufacturingWorkOrderDetailId = D.ManufacturingWorkOrderDetailId
        FROM @Temp T
        INNER JOIN ManufacturingWorkOrderDetails D
            ON D.ManufacturingWorkOrderId = @ManufacturingWorkOrderId
            AND D.RawMaterialId = T.RawMaterialId
            --AND ISNULL(D.IsDeleted, 0) = 0
        WHERE T.ManufacturingWorkOrderDetailId = 0;

        ------------------------------------------------------------
        -- Update Not Needed flag / reset provided qty when excluded
        ------------------------------------------------------------
        UPDATE D
        SET
            D.IsNotNeeded = T.IsNotNeeded,
            D.ProvidedQty = CASE
                WHEN T.IsNotNeeded = 1 THEN 0
                ELSE D.ProvidedQty
            END,
            D.UpdatedBy = @UserId,
            D.UpdatedDate = @DT,
            D.UpdatedUTCDate = @DTUTC
        FROM ManufacturingWorkOrderDetails D
        INNER JOIN @Temp T
            ON D.ManufacturingWorkOrderDetailId = T.ManufacturingWorkOrderDetailId
        WHERE D.ManufacturingWorkOrderId = @ManufacturingWorkOrderId;

        ------------------------------------------------------------
        -- Update ProvidedQty (ACCUMULATIVE) for active materials only
        ------------------------------------------------------------
        UPDATE D
        SET
            D.ProvidedQty = ISNULL(D.ProvidedQty, 0) + T.ProvidedQty,
            D.UpdatedBy = @UserId,
            D.UpdatedDate = @DT,
            D.UpdatedUTCDate = @DTUTC
        FROM ManufacturingWorkOrderDetails D
        INNER JOIN @Temp T
            ON D.ManufacturingWorkOrderDetailId = T.ManufacturingWorkOrderDetailId
        WHERE D.ManufacturingWorkOrderId = @ManufacturingWorkOrderId
            AND T.IsNotNeeded = 0
            AND T.ProvidedQty > 0;

        ------------------------------------------------------------
        -- Validate Negative Inventory
        ------------------------------------------------------------
        IF @CheckRawMaterialStock = 1
        BEGIN
            IF EXISTS
            (
                SELECT 1
                FROM RawMaterialInventory RMI
                INNER JOIN @Temp T
                    ON RMI.RawMaterialId = T.RawMaterialId
                INNER JOIN RawMaterials RM
                    ON RM.RawMaterialId = RMI.RawMaterialId
                WHERE
                    T.IsNotNeeded = 0
                    AND T.ProvidedQty > 0
                    AND
                    (
                        RMI.Inventory < 0
                        OR (RMI.Inventory - T.ProvidedQty < 0)
                    )
            )
            BEGIN
                DECLARE @ValidationMessage VARCHAR(MAX);

                SELECT TOP 1
                    @ValidationMessage = 'RawMaterials quantities cannot go negative for some records.'
                FROM RawMaterialInventory RMI
                INNER JOIN @Temp T
                    ON RMI.RawMaterialId = T.RawMaterialId
                INNER JOIN RawMaterials RM
                    ON RM.RawMaterialId = RMI.RawMaterialId
                WHERE
                    T.IsNotNeeded = 0
                    AND T.ProvidedQty > 0
                    AND
                    (
                        RMI.Inventory < 0
                        OR (RMI.Inventory - T.ProvidedQty < 0)
                    );

                ROLLBACK TRAN SubmitWorkOrderMaterials;

                SELECT
                    CAST(0 AS BIT) AS Status,
                    @ValidationMessage AS Message;

                RETURN;
            END
        END

        ------------------------------------------------------------
        -- Inventory Deduction
        ------------------------------------------------------------
        UPDATE RMI
        SET
            RMI.Inventory = RMI.Inventory - T.ProvidedQty,
            RMI.LastModifiedBy = @UserId,
            RMI.LastModifiedDate = @DT,
            RMI.LastModifiedUTCDate = @DTUTC
        FROM RawMaterialInventory RMI
        INNER JOIN @Temp T
            ON RMI.RawMaterialId = T.RawMaterialId
        WHERE T.IsNotNeeded = 0
            AND T.ProvidedQty > 0;

        ------------------------------------------------------------
        -- Activity Logs
        ------------------------------------------------------------
        DECLARE @Inc INT = 1;
        DECLARE @Cnt INT;
		DECLARE @SubjectId BIGINT;
		DECLARE @Description VARCHAR(MAX);

		CREATE TABLE #ActivityLogs (
			RowId INT IDENTITY(1, 1)
			,SubjectId BIGINT
			,Description VARCHAR(MAX)
			);

		INSERT INTO #ActivityLogs (
			SubjectId
			,Description
			)
		SELECT RMI.RawMaterialInventoryId
			,'RawMaterial Inventory has been updated from ' + CAST((RMI.Inventory + T.ProvidedQty) AS VARCHAR(100)) + ' to ' + CAST(RMI.Inventory AS VARCHAR(100)) + ' (-' + CAST(T.ProvidedQty AS VARCHAR(100)) + ') for order ' + @OrderNO
		FROM RawMaterialInventory RMI
		INNER JOIN @Temp T ON RMI.RawMaterialId = T.RawMaterialId
		WHERE T.IsNotNeeded = 0
			AND T.ProvidedQty > 0;

		SELECT @Cnt = COUNT(1)FROM #ActivityLogs;

		WHILE @Cnt >= @Inc
		BEGIN
			SELECT @SubjectId = SubjectId
				,@Description = Description
			FROM #ActivityLogs
			WHERE RowId = @Inc;

			EXEC dbo.SaveActivityLog 
                 @SubjectTypeId = @rawMaterialSubjectTypeId
				,@SubjectId = @SubjectId
				,@Description = @Description
				,@Action = 'UPDATE'
				,@CreatedBy = @UserID
				,@CreatedDate = @DT
				,@CreatedUTCDate = @DTUTC;

			SET @Inc = @Inc + 1;
		END;

		DROP TABLE #ActivityLogs;

        ------------------------------------------------------------
        -- WorkOrder Logs
        ------------------------------------------------------------
        INSERT INTO ManufacturingWorkOrderDetailsLog
        (
            ManufacturingWorkOrderDetailId,
            RawMaterialId,
            Description,
            ProvidedQty,
            MaterialProviderId,
            MaterialReceiveId,
            CreatedBy,
            CreatedDate,
            CreatedUTCDate
        )
        SELECT
            D.ManufacturingWorkOrderDetailId,
            D.RawMaterialId,
            CASE
                WHEN T.IsNotNeeded = 1 THEN 'Marked as Not Needed'
                ELSE 'Required: '
                    + CAST(ISNULL(D.RequiredQty, 0) AS VARCHAR(100))
                    + ' | Available: '
                    + CAST(RMI.Inventory AS VARCHAR(100))
            END,
            CASE
                WHEN T.IsNotNeeded = 1 THEN 0
                ELSE T.ProvidedQty
            END,
            @UserId,
            @ReceivedBy,
            @UserId,
            @DT,
            @DTUTC
        FROM ManufacturingWorkOrderDetails D
        INNER JOIN @Temp T
            ON D.ManufacturingWorkOrderDetailId = T.ManufacturingWorkOrderDetailId
        LEFT JOIN RawMaterialInventory RMI
            ON D.RawMaterialId = RMI.RawMaterialId
        WHERE
            T.IsNotNeeded = 1
         OR T.ProvidedQty > 0;

        ------------------------------------------------------------
        -- Status Calculation
        ------------------------------------------------------------
        DECLARE @Total INT, @Completed INT, @Started INT;

        SELECT
            @Total = COUNT(*),
            @Completed = SUM(
                CASE
                    WHEN ISNULL(IsNotNeeded, 0) = 1 THEN 1
                    WHEN ISNULL(RequiredQty, 0) = 0 AND ISNULL(ProvidedQty, 0) > 0 THEN 1
                    WHEN ISNULL(ProvidedQty, 0) >= ISNULL(RequiredQty, 0) THEN 1
                    ELSE 0
                END
            ),
            @Started = SUM(
                CASE
                    WHEN ISNULL(IsNotNeeded, 0) = 1 THEN 1
                    WHEN ISNULL(ProvidedQty, 0) > 0 THEN 1
                    ELSE 0
                END
            )
        FROM ManufacturingWorkOrderDetails
        WHERE ManufacturingWorkOrderId = @ManufacturingWorkOrderId

        DECLARE @FinalStatus INT = 0;

        IF @Total > 0 AND @Completed = @Total
            SET @FinalStatus = 2; -- Completed
        ELSE IF @Started > 0
            SET @FinalStatus = 1; -- Partial
        ELSE
            SET @FinalStatus = 0; -- Pending

        ------------------------------------------------------------
        -- Update Work Order
        ------------------------------------------------------------
        UPDATE ManufacturingWorkOrders
        SET
            Status = @FinalStatus,
            UpdatedBy = @UserId,
            UpdatedDate = @DT,
            UpdatedUTCDate = @DTUTC
        WHERE ManufacturingWorkOrderId = @ManufacturingWorkOrderId;

        COMMIT TRAN SubmitWorkOrderMaterials;

        SELECT CAST(1 AS BIT) AS Status, 'Work Order updated successfully.' AS Message;

    END TRY

    BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SubmitWorkOrderMaterials;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT CAST(0 AS BIT) AS STATUS
			,ERROR_MESSAGE() AS Message;
	END CATCH
END

GO

