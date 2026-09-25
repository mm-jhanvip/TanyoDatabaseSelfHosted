-- =============================================
-- Author       : MagnusMinds
-- Create date  : 27-06-2026
-- Description  : Report - Work Order Excess Usage
-- =============================================
/*
    EXEC [dbo].[ReportWorkOrderExcessUsage]
        @TenantId = 2,
        @OrderNo = NULL,
        @RawMaterialName = NULL,
        @ExcessUsageOnly = 1,
        @PageIndex = 1,
        @PageSize = 20,
        @SortBy = 'OrderNo',
        @SortOrder = 'ASC'
*/
CREATE   PROCEDURE [dbo].[ReportWorkOrderExcessUsage]
(
    @TenantId INT,
    @OrderNo VARCHAR(20) = NULL,
    @RawMaterialName VARCHAR(50) = NULL,
    @ExcessUsageOnly BIT = 0,
    @PageIndex INT = 1,
    @PageSize INT = 20,
    @SortBy VARCHAR(50) = 'OrderNo',
    @SortOrder VARCHAR(4) = 'ASC'
)
WITH ENCRYPTION
AS
BEGIN
  SET NOCOUNT ON;
    BEGIN TRY

    DROP TABLE IF EXISTS #MaterialDetail;

    SELECT
        ORD.OrderId,
        ORD.OrderNo,
        MWOD.RawMaterialId,
        RM.Title AS RawMaterialName,
        CAST(
            CASE
                WHEN ISNULL(MWOD.IsNotNeeded, 0) = 1 THEN 0
                WHEN MWOD.RequiredQty IS NULL THEN 0
                ELSE MWOD.RequiredQty
            END AS DECIMAL(18, 4)
        ) AS RequiredQty,
        CAST(ISNULL(MWOD.ProvidedQty, 0) AS DECIMAL(18, 4)) AS IssuedQty,
        CAST(
            CASE
                WHEN ISNULL(MWOD.ProvidedQty, 0) >
                    CASE
                        WHEN ISNULL(MWOD.IsNotNeeded, 0) = 1 THEN 0
                        WHEN MWOD.RequiredQty IS NULL THEN 0
                        ELSE MWOD.RequiredQty
                    END
                THEN ISNULL(MWOD.ProvidedQty, 0) -
                    CASE
                        WHEN ISNULL(MWOD.IsNotNeeded, 0) = 1 THEN 0
                        WHEN MWOD.RequiredQty IS NULL THEN 0
                        ELSE MWOD.RequiredQty
                    END
                ELSE 0
            END AS DECIMAL(18, 4)
        ) AS ExcessQty
    INTO #MaterialDetail
    FROM ManufacturingWorkOrderDetails MWOD WITH (NOLOCK)
    INNER JOIN ManufacturingWorkOrders MWO WITH (NOLOCK)
        ON MWO.ManufacturingWorkOrderId = MWOD.ManufacturingWorkOrderId
    INNER JOIN Orders ORD WITH (NOLOCK)
        ON ORD.OrderId = MWO.OrderId
    INNER JOIN OrderSetItems OSI WITH (NOLOCK)
        ON OSI.OrderSetItemId = MWO.OrderSetItemId
        AND OSI.IsDeleted = 0
    INNER JOIN RawMaterials RM WITH (NOLOCK)
        ON MWOD.RawMaterialId = RM.RawMaterialId
        AND RM.TenantId = @TenantId
    WHERE
        ISNULL(MWO.IsDeleted, 0) = 0
        AND ISNULL(MWOD.ProvidedQty, 0) > 0
        AND
        (
            @OrderNo IS NULL
            OR ORD.OrderNo LIKE '%' + @OrderNo + '%'
        )
        AND
        (
            @RawMaterialName IS NULL
            OR RM.Title LIKE '%' + @RawMaterialName + '%'
        );

    DROP TABLE IF EXISTS #OrderSummary;

    SELECT
        MD.OrderId,
        MD.OrderNo,
        SUM(MD.RequiredQty) AS TotalRequiredQty,
        SUM(MD.IssuedQty) AS TotalIssuedQty,
        SUM(MD.ExcessQty) AS ExcessQty,
        CAST(
            CASE
                WHEN SUM(MD.RequiredQty) > 0
                THEN (SUM(MD.ExcessQty) / SUM(MD.RequiredQty)) * 100
                ELSE 0
            END AS DECIMAL(18, 2)
        ) AS PercentExcess
    INTO #OrderSummary
    FROM #MaterialDetail MD
    GROUP BY MD.OrderId, MD.OrderNo
    HAVING
        @ExcessUsageOnly = 0
        OR SUM(MD.ExcessQty) > 0;

    DECLARE
        @PageTotalRequiredQty DECIMAL(18, 4) = 0,
        @PageTotalIssuedQty DECIMAL(18, 4) = 0,
        @PageTotalExcessQty DECIMAL(18, 4) = 0,
        @PagePercentExcess DECIMAL(18, 2) = 0,
        @GrandTotalRequiredQty DECIMAL(18, 4) = 0,
        @GrandTotalIssuedQty DECIMAL(18, 4) = 0,
        @GrandTotalExcessQty DECIMAL(18, 4) = 0,
        @GrandPercentExcess DECIMAL(18, 2) = 0;

    SELECT
        @GrandTotalRequiredQty = ISNULL(SUM(TotalRequiredQty), 0),
        @GrandTotalIssuedQty = ISNULL(SUM(TotalIssuedQty), 0),
        @GrandTotalExcessQty = ISNULL(SUM(ExcessQty), 0),
        @GrandPercentExcess = ISNULL(SUM(PercentExcess), 0)
    FROM #OrderSummary;

    DROP TABLE IF EXISTS #PagedOrders;

    SELECT
        OS.OrderId,
        OS.OrderNo,
        OS.TotalRequiredQty,
        OS.TotalIssuedQty,
        OS.ExcessQty,
        OS.PercentExcess,
        COUNT(1) OVER() AS TotalCount
    INTO #PagedOrders
    FROM #OrderSummary OS
    ORDER BY
        CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'ASC' THEN OS.OrderNo END ASC,
        CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'DESC' THEN OS.OrderNo END DESC,
        CASE WHEN @SortBy = 'TotalRequiredQty' AND @SortOrder = 'ASC' THEN OS.TotalRequiredQty END ASC,
        CASE WHEN @SortBy = 'TotalRequiredQty' AND @SortOrder = 'DESC' THEN OS.TotalRequiredQty END DESC,
        CASE WHEN @SortBy = 'TotalIssuedQty' AND @SortOrder = 'ASC' THEN OS.TotalIssuedQty END ASC,
        CASE WHEN @SortBy = 'TotalIssuedQty' AND @SortOrder = 'DESC' THEN OS.TotalIssuedQty END DESC,
        CASE WHEN @SortBy = 'ExcessQty' AND @SortOrder = 'ASC' THEN OS.ExcessQty END ASC,
        CASE WHEN @SortBy = 'ExcessQty' AND @SortOrder = 'DESC' THEN OS.ExcessQty END DESC,
        CASE WHEN @SortBy = 'PercentExcess' AND @SortOrder = 'ASC' THEN OS.PercentExcess END ASC,
        CASE WHEN @SortBy = 'PercentExcess' AND @SortOrder = 'DESC' THEN OS.PercentExcess END DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    SELECT
        @PageTotalRequiredQty = ISNULL(SUM(TotalRequiredQty), 0),
        @PageTotalIssuedQty = ISNULL(SUM(TotalIssuedQty), 0),
        @PageTotalExcessQty = ISNULL(SUM(ExcessQty), 0),
        @PagePercentExcess = ISNULL(SUM(PercentExcess), 0)
    FROM #PagedOrders;

    SELECT
        PO.OrderId,
        PO.OrderNo,
        PO.TotalRequiredQty,
        PO.TotalIssuedQty,
        PO.ExcessQty,
        PO.PercentExcess,
        (
            SELECT
                MD.RawMaterialId,
                MD.RawMaterialName,
                MD.RequiredQty,
                MD.IssuedQty,
                MD.ExcessQty,
                CAST(
                    CASE
                        WHEN MD.RequiredQty > 0
                        THEN (MD.ExcessQty / MD.RequiredQty) * 100
                        ELSE 0
                    END AS DECIMAL(18, 2)
                ) AS PercentExcess
            FROM #MaterialDetail MD
            WHERE MD.OrderId = PO.OrderId
                AND
                (
                    @ExcessUsageOnly = 0
                    OR MD.ExcessQty > 0
                )
            ORDER BY MD.RawMaterialName
            FOR JSON PATH
        ) AS RawMaterialDetails,
        PO.TotalCount,
        @PageTotalRequiredQty AS PageTotalRequiredQty,
        @PageTotalIssuedQty AS PageTotalIssuedQty,
        @PageTotalExcessQty AS PageTotalExcessQty,
        @PagePercentExcess AS PagePercentExcess,
        @GrandTotalRequiredQty AS GrandTotalRequiredQty,
        @GrandTotalIssuedQty AS GrandTotalIssuedQty,
        @GrandTotalExcessQty AS GrandTotalExcessQty,
        @GrandPercentExcess AS GrandPercentExcess
    FROM #PagedOrders PO;

    END TRY

    BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
    END CATCH
END

GO

