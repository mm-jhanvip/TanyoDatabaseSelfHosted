-- Job: SendClientStatistics (54c3b5e1-d8d9-4d50-b982-703ae5ae3eef)
USE [msdb];
SET NOCOUNT ON;
DECLARE @JobId uniqueidentifier; DECLARE @StepId int; DECLARE @ScheduleId int; DECLARE @ExistingScheduleId int; DECLARE @AttachedJobCount int; DECLARE @ServerName sysname; DECLARE @ExistingServerName sysname;
SELECT @JobId=job_id FROM msdb.dbo.sysjobs WHERE name=N'SendClientStatistics'; IF @JobId IS NULL BEGIN EXEC msdb.dbo.sp_add_job @job_id=N'54c3b5e1-d8d9-4d50-b982-703ae5ae3eef', @job_name=N'SendClientStatistics', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'Harsh', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; SET @JobId=N'54c3b5e1-d8d9-4d50-b982-703ae5ae3eef'; END ELSE BEGIN EXEC msdb.dbo.sp_update_job @job_id=@JobId, @new_name=N'SendClientStatistics', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'Harsh', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; END;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId) BEGIN SELECT TOP(1) @StepId=step_id FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId ORDER BY step_id DESC; EXEC msdb.dbo.sp_delete_jobstep @job_id=@JobId,@step_id=@StepId; END;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=1,@step_name=N'Send Client Statistics',@subsystem=N'TSQL',@command=N'DECLARE
    @last_X_days INT           = 1,
    @Subject     NVARCHAR(255) = NULL;

BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------------------------
    -- 1. Capture the report into a temp table
    ----------------------------------------------------------------------
    IF OBJECT_ID(''tempdb..#TenantUsage'') IS NOT NULL
        DROP TABLE #TenantUsage;

    SELECT
        ROW_NUMBER() OVER (ORDER BY o.CountOfQuotations DESC, p.CountOfProducts DESC, t.TenantID) AS RecordNumber,
        t.TenantID, 
        t.TenantName, 
        t.City,
        o.CountOfQuotations         AS NoOfQuotations,
        p.CountOfProducts           AS NoOfProducts,
        l.CountOfLeads              AS NoOfLeads,
        c.CountOfCustomers          AS NoOfCustomers,
        pimg.CountOfProductImages  AS NoOfProductImages,
        u.CountOfUsers              AS NoOfUsers,
        po.CountOfPOs               AS NoOfPurchaseOrders,
        i.CountOfInwards            AS NoOfInwards,
        v.CountOfVendors            AS NoOfVendors,
        d.CountOfDealers            AS NoOfDealers,
        comp.CountOfComplains      AS NoOfComplaints,
        cat.CountOfCatalogues       AS NoOfCatalogues,
        CASE
            WHEN nwlt.CountOfNotificationsWALifeTime > 0
                THEN CONCAT(nw.CountOfNotificationsWA, '' (LifeTime - '', nwlt.CountOfNotificationsWALifeTime, '')'')
            ELSE CAST(nw.CountOfNotificationsWA AS VARCHAR)
        END                         AS NoOfNotifications_WA,
        ne.CountOfNotificationsEmail AS NoOfNotifications_Email,
        ns.CountOfNotificationsSMS   AS NoOfNotifications_SMS,
        na.CountOfNotificationsInApp AS NoOfNotifications_InApp
    INTO #TenantUsage
    FROM [TanyoApp].[dbo].Tenants t
    CROSS APPLY ( -- Leads
        SELECT COUNT(1) CountOfLeads FROM TanyoApp.dbo.Leads l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) l
    CROSS APPLY ( -- Customers
        SELECT COUNT(1) CountOfCustomers FROM TanyoApp.dbo.Customers l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) c
    CROSS APPLY ( -- Products
        SELECT COUNT(1) CountOfProducts FROM TanyoApp.dbo.Products l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) p
    CROSS APPLY ( -- ProductImages
        SELECT COUNT(1) CountOfProductImages FROM TanyoApp.dbo.ProductImages l
        JOIN TanyoApp.dbo.Products b ON l.ProductId = b.ProductId
        WHERE b.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) pimg
    CROSS APPLY ( -- Quotations
        SELECT COUNT(1) CountOfQuotations FROM TanyoApp.dbo.Orders l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) o
    CROSS APPLY ( -- Users
        SELECT COUNT(1) CountOfUsers FROM TanyoApp.dbo.UserTenantMapping l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) u
    CROSS APPLY ( -- Purchase Orders
        SELECT COUNT(1) CountOfPOs FROM TanyoApp.dbo.POProducts l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) po
    CROSS APPLY ( -- Inwards
        SELECT COUNT(1) CountOfInwards FROM TanyoApp.dbo.InwardEntry l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) i
    CROSS APPLY ( -- Vendors
        SELECT COUNT(1) CountOfVendors FROM TanyoApp.dbo.Vendors l
        WHERE l.TenantId = t.TenantId AND l.IsDealer = 0 AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) v
    CROSS APPLY ( -- Dealers
        SELECT COUNT(1) CountOfDealers FROM TanyoApp.dbo.Vendors l
        WHERE l.TenantId = t.TenantId AND l.IsDealer = 1 AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) d
    CROSS APPLY ( -- Complaints
        SELECT COUNT(1) CountOfComplains FROM TanyoApp.dbo.Complains l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) comp
    CROSS APPLY ( -- Catalogue
        SELECT COUNT(1) CountOfCatalogues FROM TanyoApp.dbo.Catalogue l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) cat
    CROSS APPLY ( -- Notifications WhatsApp LifeTime
        SELECT COUNT(1) CountOfNotificationsWALifeTime FROM TanyoApp.dbo.NotificationManagement l
        WHERE l.TenantId = t.TenantId AND l.NotificationMethod = ''WhatsApp''
    ) nwlt
    CROSS APPLY ( -- Notifications WhatsApp
        SELECT COUNT(1) CountOfNotificationsWA FROM TanyoApp.dbo.NotificationManagement l
        WHERE l.TenantId = t.TenantId AND l.NotificationMethod = ''WhatsApp'' AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) nw
    CROSS APPLY ( -- Notifications Email
        SELECT COUNT(1) CountOfNotificationsEmail FROM TanyoApp.dbo.NotificationManagement l
        WHERE l.TenantId = t.TenantId AND l.NotificationMethod = ''Email'' AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) ne
    CROSS APPLY ( -- Notifications SMS
        SELECT COUNT(1) CountOfNotificationsSMS FROM TanyoApp.dbo.NotificationManagement l
        WHERE l.TenantId = t.TenantId AND l.NotificationMethod = ''SMS'' AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) ns
    CROSS APPLY ( -- In-App Notifications
        SELECT COUNT(1) CountOfNotificationsInApp FROM TanyoApp.dbo.Notifications l
        WHERE l.TenantId = t.TenantId AND DATEDIFF(d, l.CreatedDate, GETDATE()) <= @last_X_days
    ) na
    WHERE NOT (
        CountOfLeads = 0 AND CountOfCustomers = 0 AND CountOfQuotations = 0 AND 
        CountOfProducts = 0 AND CountOfProductImages = 0 AND CountOfUsers = 0 AND 
        CountOfInwards = 0 AND CountOfComplains = 0 AND CountOfCatalogues = 0 AND 
        CountOfNotificationsWA = 0 AND CountOfNotificationsEmail = 0 AND 
        CountOfNotificationsSMS = 0 AND CountOfNotificationsInApp = 0
    )
    AND TenantId NOT IN (2, 14, 20, 28, 43, 76) -- internal tenants
    ORDER BY CountOfQuotations DESC, CountOfProducts DESC, TenantId;

    ----------------------------------------------------------------------
    -- 2. Exit if no activity found
    ----------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM #TenantUsage)
    BEGIN
        PRINT ''No tenant activity found for the selected period - no email sent.'';
        RETURN;
    END

    ----------------------------------------------------------------------
    -- 3. Build the HTML email body
    ----------------------------------------------------------------------
    DECLARE @HTML         NVARCHAR(MAX);
    DECLARE @TableRows    NVARCHAR(MAX);
    DECLARE @ReportDate   NVARCHAR(30) = CONVERT(NVARCHAR(30), GETDATE(), 106);

    IF @Subject IS NULL
        SET @Subject = N''Client Statistics for date: '' + CONVERT(NVARCHAR(10), GETDATE(), 101) + N''.'';

    SET @TableRows = CAST((
        SELECT
            td = RecordNumber,             '''',
            td = TenantID,                 '''',
            td = TenantName,               '''',
            td = ISNULL(NULLIF(City, ''''), ''-''), '''',
            td = NoOfQuotations,           '''',
            td = NoOfProducts,             '''',
            td = NoOfLeads,                '''',
            td = NoOfCustomers,            '''',
            td = NoOfProductImages,        '''',
            td = NoOfUsers,                '''',
            td = NoOfPurchaseOrders,       '''',
            td = NoOfInwards,              '''',
            td = NoOfVendors,              '''',
            td = NoOfDealers,              '''',
            td = NoOfComplaints,           '''',
            td = NoOfCatalogues,           '''',
            td = NoOfNotifications_WA,     '''',
            td = NoOfNotifications_Email,  '''',
            td = NoOfNotifications_SMS,    '''',
            td = NoOfNotifications_InApp,  ''''
        FROM #TenantUsage
        ORDER BY NoOfQuotations DESC, NoOfProducts DESC, TenantId
        FOR XML PATH(''tr''), TYPE
    ) AS NVARCHAR(MAX));

    SET @HTML =
        N''<!DOCTYPE html>'' +
        N''<html>'' +
        N''<head>'' +
        N''<meta name="viewport" content="width=device-width, initial-scale=1.0" />'' +
        N''<style>'' +
        N''  body { font-family: Arial, sans-serif; background-color: #f4f6f9; margin: 0; padding: 10px; color: #333; -webkit-text-size-adjust: 100%; }'' +
        N''  .email-container { background-color: #ffffff; padding: 12px; border-radius: 6px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); }'' +
        N''  .table-wrapper { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }'' +
        N''  table { border-collapse: collapse; min-width: 1400px; width: 100%; font-size: 12px; }'' +
        N''  th { background-color: #1E293B; color: #FFFFFF; font-weight: bold; padding: 10px 6px; text-align: center; border: 1px solid #334155; font-size: 13px; line-height: 1.3; vertical-align: middle; }'' +
        N''  td { padding: 8px 6px; text-align: center; border: 1px solid #CBD5E1; font-size: 12px; color: #1E293B; vertical-align: middle; }'' +
        N''  tr:nth-child(even) { background-color: #F8FAFC; }'' +
        N''</style>'' +
        N''</head>'' +
        N''<body>'' +
        N''<div class="email-container">'' +
        N''  <div class="table-wrapper">'' +
        N''    <table border="1" cellpadding="0" cellspacing="0" align="center">'' +
        N''      <thead>'' +
        N''        <tr>'' +
        N''          <th>Record
Number</th>'' +
        N''          <th>Tenant
ID</th>'' +
        N''          <th>Tenant
Name</th>'' +
        N''          <th>City</th>'' +
        N''          <th>NoOf
Quotations</th>'' +
        N''          <th>NoOf
Products</th>'' +
        N''          <th>NoOf
Leads</th>'' +
        N''          <th>NoOf
Customers</th>'' +
        N''          <th>NoOfProduct
Images</th>'' +
        N''          <th>NoOf
Users</th>'' +
        N''          <th>NoOfPurchase
Orders</th>'' +
        N''          <th>NoOf
Inwards</th>'' +
        N''          <th>NoOf
Vendors</th>'' +
        N''          <th>NoOf
Dealers</th>'' +
        N''          <th>NoOf
Complaints</th>'' +
        N''          <th>NoOf
Catalogues</th>'' +
        N''          <th>NoOfNotifications_
WA</th>'' +
        N''          <th>NoOfNotifications_
Email</th>'' +
        N''          <th>NoOfNotifications_
SMS</th>'' +
        N''          <th>NoOfNotifications_
InApp</th>'' +
        N''        </tr>'' +
        N''      </thead>'' +
        N''      <tbody>'' +
        @TableRows +
        N''      </tbody>'' +
        N''    </table>'' +
        N''  </div>'' +
        N''</div>'' +
        N''</body>'' +
        N''</html>'';

    ----------------------------------------------------------------------
    -- 4. Send the email via Database Mail
    ----------------------------------------------------------------------
    EXEC msdb.dbo.sp_send_dbmail
         @profile_name  = ''DB EMail'',
        @recipients    = ''tshah@magnusminds.net'',
        @subject       = @Subject,
        @body          = @HTML,
        @body_format   = ''HTML'';

    DROP TABLE #TenantUsage;
END
GO',@database_name=N'TanyoApp',@database_user_name=NULL,@on_success_action=1,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId) BEGIN SELECT TOP(1) @ScheduleId=schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId ORDER BY schedule_id DESC; EXEC msdb.dbo.sp_detach_schedule @job_id=@JobId,@schedule_id=@ScheduleId; END;
SET @ScheduleId=NULL; SET @ExistingScheduleId=NULL; SET @AttachedJobCount=0; SELECT @ExistingScheduleId=schedule_id FROM msdb.dbo.sysschedules WHERE name=N'SC_ClientStatistics'; IF @ExistingScheduleId IS NOT NULL BEGIN SELECT @AttachedJobCount=COUNT(*) FROM msdb.dbo.sysjobschedules WHERE schedule_id=@ExistingScheduleId; IF @AttachedJobCount>0 THROW 51000,'Cannot update shared SQL Agent schedule; refusing to change another job.',1; SET @ScheduleId=@ExistingScheduleId; EXEC msdb.dbo.sp_update_schedule @schedule_id=@ScheduleId,@name=N'SC_ClientStatistics',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_subday_interval=0,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20260804,@active_end_date=99991231,@active_start_time=80000,@active_end_time=235959; END ELSE BEGIN EXEC msdb.dbo.sp_add_schedule @schedule_id=@ScheduleId OUTPUT,@schedule_name=N'SC_ClientStatistics',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20260804,@active_end_date=99991231,@active_start_time=80000,@active_end_time=235959; END; EXEC msdb.dbo.sp_attach_schedule @job_id=@JobId,@schedule_id=@ScheduleId;
SET @ServerName=N'vm-tanyo-app-pr'; IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysjobservers WHERE job_id=@JobId AND server_id=(SELECT srvid FROM master.dbo.sysservers WHERE srvname=@ServerName)) EXEC msdb.dbo.sp_add_jobserver @job_id=@JobId,@server_name=@ServerName;
