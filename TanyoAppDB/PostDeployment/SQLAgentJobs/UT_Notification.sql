-- Job: UT_Notification (71d8ab81-b77d-492d-ad63-3267b08c7bdf)
USE [msdb];
SET NOCOUNT ON;
DECLARE @JobId uniqueidentifier; DECLARE @StepId int; DECLARE @ScheduleId int; DECLARE @ExistingScheduleId int; DECLARE @AttachedJobCount int; DECLARE @ServerName sysname; DECLARE @ExistingServerName sysname;
SELECT @JobId=job_id FROM msdb.dbo.sysjobs WHERE name=N'UT_Notification'; IF @JobId IS NULL BEGIN EXEC msdb.dbo.sp_add_job @job_id=N'71d8ab81-b77d-492d-ad63-3267b08c7bdf', @job_name=N'UT_Notification', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'Harsh', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; SET @JobId=N'71d8ab81-b77d-492d-ad63-3267b08c7bdf'; END ELSE BEGIN EXEC msdb.dbo.sp_update_job @job_id=@JobId, @new_name=N'UT_Notification', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'Harsh', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; END;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId) BEGIN SELECT TOP(1) @StepId=step_id FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId ORDER BY step_id DESC; EXEC msdb.dbo.sp_delete_jobstep @job_id=@JobId,@step_id=@StepId; END;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=1,@step_name=N'Send Alert For UT Views',@subsystem=N'TSQL',@command=N'DECLARE @SchemaName NVARCHAR(128);
DECLARE @ViewName NVARCHAR(128);
DECLARE @FullName NVARCHAR(256);
DECLARE @DynamicSQL NVARCHAR(MAX);
DECLARE @RecordCount INT;
DECLARE @EmailBody NVARCHAR(MAX);
DECLARE @HasPasses BIT = 0;
DECLARE @HasFails BIT = 0;
DECLARE @EmailSubject NVARCHAR(255);
DECLARE @TotalViews INT;
DECLARE @FailCount INT;
DECLARE @PassCount INT;
DECLARE @Date DATE = CAST(GETDATE() AS date)

SET NOCOUNT ON;

DECLARE @ViewsList TABLE (
    ID INT IDENTITY(1,1),
    SchemaName NVARCHAR(128),
    ViewName NVARCHAR(128)
);

INSERT INTO @ViewsList (SchemaName, ViewName)
SELECT s.name, v.name
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE v.name LIKE ''UT_%'';

DECLARE @PassResults TABLE (ViewName NVARCHAR(256), RecordCount INT);
DECLARE @FailResults TABLE (ViewName NVARCHAR(256), RecordCount INT);

DECLARE @CurrentID INT = 1;
DECLARE @MaxID INT = (SELECT ISNULL(MAX(ID), 0) FROM @ViewsList);

WHILE @CurrentID <= @MaxID
BEGIN
    SELECT @SchemaName = SchemaName,
           @ViewName = ViewName
    FROM @ViewsList
    WHERE ID = @CurrentID;

    SET @FullName = QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@ViewName);
    SET @DynamicSQL = N''SELECT @CountOUT = COUNT(*) FROM '' + @FullName;

    EXEC sp_executesql
        @stmt = @DynamicSQL,
        @params = N''@CountOUT INT OUTPUT'',
        @CountOUT = @RecordCount OUTPUT;

    IF @RecordCount = 0
    BEGIN
        INSERT INTO @PassResults (ViewName, RecordCount) VALUES (@ViewName, @RecordCount);
    END
    ELSE
    BEGIN
        INSERT INTO @FailResults (ViewName, RecordCount) VALUES (@ViewName, @RecordCount);
    END

    SET @CurrentID = @CurrentID + 1;
END

SET @TotalViews = @MaxID;
SET @FailCount = (SELECT COUNT(*) FROM @FailResults);
SET @PassCount = (SELECT COUNT(*) FROM @PassResults);  

IF EXISTS (SELECT 1 FROM @PassResults) SET @HasPasses = 1;
IF EXISTS (SELECT 1 FROM @FailResults) SET @HasFails = 1;

SET @EmailBody = N''<html>
<head>
<style>
    body { font-family: Arial, Helvetica, sans-serif; color: #333; }
    h3 { color: #333; margin-top: 20px; }
    table { border-collapse: collapse; width: 80%; min-width: 600px; margin-top: 10px; margin-bottom: 20px; box-shadow: 0 2px 3px rgba(0,0,0,0.1); }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 10px; }
    th { background-color: #f4f4f4; color: #333; font-weight: bold; }
    .status-pass { color: green; font-weight: bold; }
    .status-fail { color: red; font-weight: bold; }
</style>
</head>
<body>'';

IF @HasFails = 1
BEGIN
    SET @EmailBody = @EmailBody + N''
    <h3 style="color: #dc3545;">Action Required: Data Integrity checks failed in TanyoApp</h3>
    <p>The following views have returned records, indicating a failure:</p>
    <table>
    <tr>
        <th>View Name</th>
        <th>Status</th>
        <th>Total Records</th>
    </tr>'';

    SELECT @EmailBody = @EmailBody + 
        N''<tr><td>'' + ViewName + N''</td><td class="status-fail">FAIL</td><td>'' + CAST(RecordCount AS NVARCHAR(20)) + N''</td></tr>''
    FROM @FailResults;

    SET @EmailBody = @EmailBody + N''</table>'';
END

IF @HasPasses = 1
BEGIN
    SET @EmailBody = @EmailBody + N''
    <h3 style="color: #28a745;">Passed Checks</h3>
    <p>The following views have passed the data integrity checks:</p>
    <table>
    <tr>
        <th>View Name</th>
        <th>Status</th>
        <th>Total Records</th>
    </tr>'';

    SELECT @EmailBody = @EmailBody + 
        N''<tr><td>'' + ViewName + N''</td><td class="status-pass">PASS</td><td>'' + CAST(RecordCount AS NVARCHAR(20)) + N''</td></tr>''
    FROM @PassResults;

    SET @EmailBody = @EmailBody + N''</table>'';
END

SET @EmailBody = @EmailBody + N''</body></html>'';

IF @HasFails = 1
    SET @EmailSubject = CAST(@FailCount AS NVARCHAR(10)) + '' of '' + CAST(@TotalViews AS NVARCHAR(10)) + '' Views Failed Data Integrity Checks on '' + FORMAT(@Date, ''dd/MM/yyyy'') + ''.'';
ELSE
    SET @EmailSubject = ''Data Integrity Checks Passed Successfully'';

IF @HasPasses = 1 OR @HasFails = 1
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = ''DB EMail'',
        @recipients = ''mm.jhanvip@gmail.com;harsh@magnusminds.net;tshah@magnusminds.net;parshwa@magnusminds.net'',
        @subject = @EmailSubject,
        @body = @EmailBody,
        @body_format = ''HTML'';
END',@database_name=N'TanyoApp',@database_user_name=NULL,@on_success_action=1,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId) BEGIN SELECT TOP(1) @ScheduleId=schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId ORDER BY schedule_id DESC; EXEC msdb.dbo.sp_detach_schedule @job_id=@JobId,@schedule_id=@ScheduleId; END;
SET @ScheduleId=NULL; SET @ExistingScheduleId=NULL; SET @AttachedJobCount=0; SELECT @ExistingScheduleId=schedule_id FROM msdb.dbo.sysschedules WHERE name=N'SC Send UT notification'; IF @ExistingScheduleId IS NOT NULL BEGIN SELECT @AttachedJobCount=COUNT(*) FROM msdb.dbo.sysjobschedules WHERE schedule_id=@ExistingScheduleId; IF @AttachedJobCount>0 THROW 51000,'Cannot update shared SQL Agent schedule; refusing to change another job.',1; SET @ScheduleId=@ExistingScheduleId; EXEC msdb.dbo.sp_update_schedule @schedule_id=@ScheduleId,@name=N'SC Send UT notification',@enabled=1,@freq_type=4,@freq_interval=1,@freq_subday_type=1,@freq_subday_interval=0,@freq_relative_interval=0,@freq_recurrence_factor=0,@active_start_date=20260722,@active_end_date=99991231,@active_start_time=80000,@active_end_time=235959; END ELSE BEGIN EXEC msdb.dbo.sp_add_schedule @schedule_id=@ScheduleId OUTPUT,@schedule_name=N'SC Send UT notification',@enabled=1,@freq_type=4,@freq_interval=1,@freq_subday_type=1,@freq_relative_interval=0,@freq_recurrence_factor=0,@active_start_date=20260722,@active_end_date=99991231,@active_start_time=80000,@active_end_time=235959; END; EXEC msdb.dbo.sp_attach_schedule @job_id=@JobId,@schedule_id=@ScheduleId;
SET @ServerName=N'vm-tanyo-app-pr'; IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysjobservers WHERE job_id=@JobId AND server_id=(SELECT srvid FROM master.dbo.sysservers WHERE srvname=@ServerName)) EXEC msdb.dbo.sp_add_jobserver @job_id=@JobId,@server_name=@ServerName;
