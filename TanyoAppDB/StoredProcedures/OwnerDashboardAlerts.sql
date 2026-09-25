-- =============================================================================
-- SP Name   : OwnerDashboardAlerts
-- Module    : Owner Dashboard - Today's Alerts (Top Strip)
-- Params    : @TenantId INT, @Month INT, @Year INT
-- Returns   : The 5 exception indicators shown on the dashboard alerts strip.
--
-- KPI Logic:
--   OverdueOutstanding30Plus = Outstanding receivables with invoice age > 30d.
--   SalesTargetGap           = MAX(0, monthly target - achieved to date).
--   PendingFollowUps         = Open leads with a follow-up due on/before today.
--   SlowMovingStockValue     = Stock with no sale in 60 days (60-day window).
--   OpenComplaints           = Complaints Status IN (1 Open, 2 InProgress).
-- =============================================================================

CREATE   PROCEDURE [dbo].[OwnerDashboardAlerts]
    @TenantId INT,
    @Month    INT,
    @Year     INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today      DATE     = CAST(GETDATE() AS DATE);
    DECLARE @MonthStart DATETIME = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @MonthEnd   DATETIME = EOMONTH(@MonthStart);
    DECLARE @SlowMovingDays INT = 60;

    -- 1. Overdue outstanding (>30 days invoice age)
    DECLARE @OverdueOutstanding DECIMAL(18, 2) =
    (
        SELECT ISNULL(SUM(CAST(o.TotalAmount AS DECIMAL(18, 2)) - ISNULL(pp.Paid, 0)), 0)
        FROM dbo.Orders o WITH (NOLOCK)
        LEFT JOIN
        (
            SELECT p.OrderId, SUM(CAST(p.ReceivedAmount AS DECIMAL(18, 2))) AS Paid
            FROM dbo.Payments p WITH (NOLOCK)
            WHERE p.TenantId = @TenantId AND p.IsDeleted = 0 AND p.PaymentStatus = 1
            GROUP BY p.OrderId
        ) pp ON pp.OrderId = o.OrderId
        WHERE o.TenantId = @TenantId
          AND o.IsArchive = 0
          AND o.Status >= 2 AND o.Status NOT IN (6, 8)
          AND o.ApprovedDate IS NOT NULL
          AND DATEDIFF(DAY, o.ApprovedDate, @Today) > 30
          AND CAST(o.TotalAmount AS DECIMAL(18, 2)) - ISNULL(pp.Paid, 0) > 0
    );

    -- 2. Sales target gap for the month
    DECLARE @MonthlyTarget DECIMAL(18, 2) =
        ISNULL((SELECT SUM(st.TargetAmount) FROM dbo.SalesTargets st WITH (NOLOCK)
                WHERE st.TenantId = @TenantId AND st.Month = @Month AND st.Year = @Year AND st.IsDeleted = 0), 0);

    DECLARE @Achieved DECIMAL(18, 2) =
        ISNULL((SELECT SUM(CAST(o.AmountBeforeGST AS DECIMAL(18, 2)))
                FROM dbo.Orders o WITH (NOLOCK)
                WHERE o.TenantId = @TenantId AND o.IsArchive = 0 AND o.Status >= 2 AND o.Status NOT IN (6, 8)
                  AND o.ApprovedDate IS NOT NULL
                  AND CAST(o.ApprovedDate AS DATE) BETWEEN CAST(@MonthStart AS DATE) AND @MonthEnd), 0);

    DECLARE @TargetGap DECIMAL(18, 2) =
        CASE WHEN @MonthlyTarget - @Achieved > 0 THEN @MonthlyTarget - @Achieved ELSE 0 END;

    -- 3. Pending follow-ups
    DECLARE @PendingFollowUps INT =
    (
        SELECT COUNT(DISTINCT fl.LeadId)
        FROM dbo.FollowUpLeads fl WITH (NOLOCK)
        JOIN dbo.Leads l WITH (NOLOCK) ON l.LeadId = fl.LeadId
        WHERE l.TenantId = @TenantId
          AND l.Status NOT IN (4, 5, 6)
          AND fl.FollowUpDate IS NOT NULL
          AND fl.FollowUpDate <= @Today
    );

    -- 4. Slow moving stock value (no sale in @SlowMovingDays days)
    DECLARE @SlowMovingStockValue DECIMAL(18, 2) =
    (
        SELECT ISNULL(SUM(CAST(pq.Quantity AS DECIMAL(18, 2)) * CAST(p.CostPrice AS DECIMAL(18, 2))), 0)
        FROM dbo.ProductQuantities pq WITH (NOLOCK)
        JOIN dbo.Products p WITH (NOLOCK) ON p.ProductId = pq.ProductId
        WHERE p.TenantId = @TenantId
          AND pq.Quantity > 0
          AND DATEDIFF(DAY,
                       ISNULL((SELECT MAX(il.CreatedDate) FROM dbo.InventoryLogs il WITH (NOLOCK)
                               WHERE il.ProductId = p.ProductId AND il.OrderNo IS NOT NULL),
                              (SELECT MIN(pq2.QuantityDate) FROM dbo.ProductQuantities pq2 WITH (NOLOCK)
                               WHERE pq2.ProductId = p.ProductId)),
                       @Today) > @SlowMovingDays
    );

    -- 5. Open complaints
    DECLARE @OpenComplaints INT =
    (
        SELECT Count(1) FROM dbo.Complains cp WITH (NOLOCK)
        WHERE cp.TenantId = @TenantId AND cp.Status IN (1, 2)
    );

    SELECT
        @OverdueOutstanding       AS OverdueOutstanding30Plus,
        @TargetGap                AS SalesTargetGap,
        @PendingFollowUps         AS PendingFollowUps,
        @SlowMovingStockValue     AS SlowMovingStockValue,
        @OpenComplaints           AS OpenComplaints;
END;

GO

