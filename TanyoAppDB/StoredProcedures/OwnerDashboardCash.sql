-- =============================================================================
-- SP Name   : OwnerDashboardCash
-- Module    : Owner Dashboard - Cash ("Are We Collecting What We Sell?")
-- Params    : @TenantId INT
-- Returns   : Today/MTD collection, outstanding + aging buckets (invoice age
--             from approval date), overdue (>30 days), due next 7 days.
--
-- KPI Logic:
--   Collection        = SUM(Payments.ReceivedAmount) WHERE PaymentStatus = 1
--                       (approved payments only), grouped by received date.
--   Outstanding       = Per approved order: TotalAmount - approved payments.
--                       Invoice age = DATEDIFF(day, ApprovedDate, today).
--   Aging buckets     : 0-30 / 31-60 / 61-90 / 90+ days.
--   DueNext7Days      = Outstanding on orders with DeliveryDate within the
--                       next 7 days (delivery-linked collection schedule).
-- =============================================================================

CREATE   PROCEDURE [dbo].[OwnerDashboardCash]
    @TenantId INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    ;WITH ApprovedOrders AS
    (
        SELECT
            o.OrderId,
            CAST(o.TotalAmount AS DECIMAL(18, 2))                                        AS InvoiceValue,
            o.DeliveryDate
        FROM dbo.Orders o WITH (NOLOCK)
        WHERE o.TenantId = @TenantId
          AND o.IsArchive = 0
          AND o.Status >= 2 AND o.Status NOT IN (6, 8)        -- Won
    ),
    PaidPerOrder AS
    (
        SELECT p.OrderId, SUM(CAST(p.ReceivedAmount AS DECIMAL(18, 2))) AS Paid
        FROM dbo.Payments p WITH (NOLOCK)
        WHERE p.TenantId = @TenantId
          AND p.IsDeleted = 0
          AND p.PaymentStatus = 1                                       -- Approved payment
          AND p.OrderId IS NOT NULL
        GROUP BY p.OrderId
    ),
    Outstanding AS
    (
        SELECT
            ao.OrderId,
            ao.InvoiceValue,
            ao.DeliveryDate,
            ao.InvoiceValue - ISNULL(po.Paid, 0)                        AS Balance
        FROM ApprovedOrders ao
        LEFT JOIN PaidPerOrder po ON po.OrderId = ao.OrderId
        WHERE ao.InvoiceValue - ISNULL(po.Paid, 0) > 0
    )
    SELECT
        (SELECT ISNULL(SUM(CAST(p.ReceivedAmount AS DECIMAL(18, 2))), 0)
         FROM dbo.Payments p WITH (NOLOCK)
         WHERE p.TenantId = @TenantId AND p.IsDeleted = 0 AND p.PaymentStatus = 1
           AND CAST(p.ReceivedDate AS DATE) = @Today)                   AS TodayCollection,

        (SELECT ISNULL(SUM(CAST(p.ReceivedAmount AS DECIMAL(18, 2))), 0)
         FROM dbo.Payments p WITH (NOLOCK)
         WHERE p.TenantId = @TenantId AND p.IsDeleted = 0 AND p.PaymentStatus = 1
           AND YEAR(p.ReceivedDate) = YEAR(@Today) AND MONTH(p.ReceivedDate) = MONTH(@Today))
                                                                         AS MTDCollection,

        ISNULL(SUM(o.Balance), 0)                                        AS TotalOutstanding,

        ISNULL(SUM(CASE WHEN DATEDIFF(DAY, ao.ApprovedDate, @Today) > 30
                        THEN o.Balance ELSE 0 END), 0)                   AS OverdueOutstanding,

        ISNULL(SUM(CASE WHEN o.DeliveryDate IS NOT NULL
                         AND o.DeliveryDate >= @Today
                         AND o.DeliveryDate < DATEADD(DAY, 7, @Today)
                        THEN o.Balance ELSE 0 END), 0)                   AS DueNext7Days,

        ISNULL(SUM(CASE WHEN DATEDIFF(DAY, ao.ApprovedDate, @Today) <= 30
                        THEN o.Balance ELSE 0 END), 0)                   AS Aging0To30,
        ISNULL(SUM(CASE WHEN DATEDIFF(DAY, ao.ApprovedDate, @Today) BETWEEN 31 AND 60
                        THEN o.Balance ELSE 0 END), 0)                   AS Aging31To60,
        ISNULL(SUM(CASE WHEN DATEDIFF(DAY, ao.ApprovedDate, @Today) BETWEEN 61 AND 90
                        THEN o.Balance ELSE 0 END), 0)                   AS Aging61To90,
        ISNULL(SUM(CASE WHEN DATEDIFF(DAY, ao.ApprovedDate, @Today) > 90
                        THEN o.Balance ELSE 0 END), 0)                   AS Aging90Plus
    FROM Outstanding o
    JOIN dbo.Orders ao WITH (NOLOCK) ON ao.OrderId = o.OrderId;
END;

GO

