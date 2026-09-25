/*
EXEC [dbo].[GetManufacturingAllWorkflow]
    @TenantId = 1206
*/
CREATE   PROCEDURE [dbo].[GetManufacturingAllWorkflow]
(
    @TenantId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        ;WITH WorkflowCounts AS
        (
            SELECT
                omw.ManufacturingWorkflowId
                ,PendingCount =
                    SUM(CASE
                            WHEN omw.ManufacturingStatus = 0 THEN 1
                            ELSE 0
                        END)
                ,InProgressCount =
                    SUM(CASE
                            WHEN omw.ManufacturingStatus = 1 THEN 1
                            ELSE 0
                        END)
                ,SubmitCount =
                    SUM(CASE
                            WHEN omw.ManufacturingStatus = 2 THEN 1
                            ELSE 0
                        END)
            FROM dbo.OrderManufacturingWorkflows omw WITH (NOLOCK)
            INNER JOIN dbo.Orders o WITH (NOLOCK)
                ON o.OrderId = omw.OrderId
               AND o.TenantId = @TenantId
               AND o.IsArchive = 0
            INNER JOIN dbo.OrderSetItems osi WITH (NOLOCK)
                ON osi.OrderSetItemId = omw.OrderSetItemId
               AND osi.ItemStatus = 1
            WHERE omw.ManufacturingStatus IN (0, 1, 2)
            GROUP BY
                omw.ManufacturingWorkflowId
        ),
        StockCounts AS
        (
            SELECT
                ManufacturingWorkflowId
                ,SUM(StockQty) AS PartialStockCount
            FROM dbo.ManufacturingWorkflowStock WITH (NOLOCK)
            GROUP BY ManufacturingWorkflowId
        )
        SELECT
            mw.ManufacturingWorkflowId
            ,mw.WorkflowName
            ,ISNULL(wc.PendingCount, 0) AS PendingCount
            ,ISNULL(wc.InProgressCount, 0) AS InProgressCount
            ,ISNULL(wc.SubmitCount, 0) AS SubmitCount
            ,ISNULL(sc.PartialStockCount, 0) AS PartialStockCount
            ,ISNULL(wc.PendingCount, 0)
            + ISNULL(wc.InProgressCount, 0)
            + ISNULL(wc.SubmitCount, 0) AS [Count]
        FROM dbo.ManufacturingWorkflows mw WITH (NOLOCK)
        LEFT JOIN WorkflowCounts wc WITH (NOLOCK)
            ON wc.ManufacturingWorkflowId = mw.ManufacturingWorkflowId
        LEFT JOIN StockCounts sc WITH (NOLOCK)
            ON sc.ManufacturingWorkflowId = mw.ManufacturingWorkflowId
        WHERE mw.TenantId = @TenantId;

    END TRY

    BEGIN CATCH
        DECLARE @ObjectName VARCHAR(500),
                @ErrorMsg VARCHAR(MAX);

        SET @ObjectName = OBJECT_NAME(@@PROCID);
        SET @ErrorMsg = ERROR_MESSAGE();

        EXEC [dbo].[SaveDBErrorLog]
            @ObjectName = @ObjectName,
            @ErrorMsg = @ErrorMsg;
    END CATCH
END

GO

