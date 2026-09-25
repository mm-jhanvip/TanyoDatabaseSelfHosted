-- =============================================================================
-- SP Name   : OwnerDashboardSales
-- Module    : Owner Dashboard - Sales ("Are We Selling Enough?")
-- Params    : @TenantId INT, @Month INT, @Year INT
-- Returns   : Monthly target vs achieved, order count, AOV, lead conversion.
--
-- KPI Logic (documented for owner's team):
--   MonthlyTarget     = SUM(SalesTargets.TargetAmount) for tenant + month.
--                       (Store target = sum of per-rep targets.)
--   AchievedAmount    = SUM(Orders.AmountBeforeGST) of APPROVED orders
--   OrdersWon           = Orders won in period (Status >= 2, excl. Canceled/Declined).
--   TargetGap         = MonthlyTarget - AchievedAmount (can be negative).
--   AchievementPct    = Achieved / Target * 100 (0 when target is 0).
--   OrderCount        = COUNT of approved orders in period.
--   AverageOrderValue = Achieved / OrderCount (0 when no orders).
--   NewLeadsCount     = COUNT(Leads) created in period (excludes deleted).
--   LeadConversionPct = OrdersWon / NewLeads * 100 (0 when no leads).
-- =============================================================================

CREATE   PROCEDURE [dbo].[OwnerDashboardSales]
    @TenantId INT,
    @Month    INT,
    @Year     INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonthStart DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @MonthEnd   DATE = EOMONTH(@MonthStart);

    ;WITH SalesData AS
    (
        SELECT
            SUM(CAST(o.AmountBeforeGST AS DECIMAL(18, 2)))                        AS AchievedAmount,
            COUNT(o.OrderId)                                                      AS OrderCount
        FROM dbo.Orders o WITH (NOLOCK)
        WHERE o.TenantId = @TenantId
          AND o.IsArchive = 0
          AND o.Status >= 2 AND o.Status NOT IN (6, 8)        -- Won (Approved, InProgress, Completed, Delivered, MaterialReceive)
          AND o.ApprovedDate BETWEEN @MonthStart AND @MonthEnd
    ),
    LeadData AS
    (
        SELECT COUNT(l.LeadId) AS NewLeadsCount
        FROM dbo.Leads l WITH (NOLOCK)
        WHERE l.TenantId = @TenantId
          AND l.Status <> 6                                 -- exclude Delete
          AND l.CreatedDate BETWEEN @MonthStart AND @MonthEnd
    ),
    TargetData AS
    (
        SELECT ISNULL(SUM(st.TargetAmount), 0) AS MonthlyTarget
        FROM dbo.SalesTargets st WITH (NOLOCK)
        WHERE st.TenantId = @TenantId
          AND st.Month = @Month
          AND st.Year  = @Year
          AND st.IsDeleted = 0
    )
    SELECT
        t.MonthlyTarget,
        ISNULL(s.AchievedAmount, 0)                                                AS AchievedAmount,
        t.MonthlyTarget - ISNULL(s.AchievedAmount, 0)                              AS TargetGap,
        CASE WHEN t.MonthlyTarget > 0
             THEN (ISNULL(s.AchievedAmount, 0) * 100.0) / t.MonthlyTarget
             ELSE 0 END                                                            AS AchievementPct,
        ISNULL(s.OrderCount, 0)                                                    AS OrderCount,
        CASE WHEN ISNULL(s.OrderCount, 0) > 0
             THEN ISNULL(s.AchievedAmount, 0) / s.OrderCount
             ELSE 0 END                                                            AS AverageOrderValue,
        ISNULL(ld.NewLeadsCount, 0)                                                AS NewLeadsCount,
        CASE WHEN ISNULL(ld.NewLeadsCount, 0) > 0
             THEN (ISNULL(s.OrderCount, 0) * 100.0) / ld.NewLeadsCount
             ELSE 0 END                                                            AS LeadConversionPct
    FROM TargetData t
    CROSS JOIN SalesData s
    CROSS JOIN LeadData ld;
END;

GO

