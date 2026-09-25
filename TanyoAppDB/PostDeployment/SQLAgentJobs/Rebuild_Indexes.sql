-- Job: Rebuild Indexes (e272453d-7bd6-4d51-8ced-3b6d135c7c7a)
USE [msdb];
SET NOCOUNT ON;
DECLARE @JobId uniqueidentifier; DECLARE @StepId int; DECLARE @ScheduleId int; DECLARE @ExistingScheduleId int; DECLARE @AttachedJobCount int; DECLARE @ServerName sysname; DECLARE @ExistingServerName sysname;
SELECT @JobId=job_id FROM msdb.dbo.sysjobs WHERE name=N'Rebuild Indexes'; IF @JobId IS NULL BEGIN EXEC msdb.dbo.sp_add_job @job_id=N'e272453d-7bd6-4d51-8ced-3b6d135c7c7a', @job_name=N'Rebuild Indexes', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'vm-tanyo-app-pr\magnusminds', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; SET @JobId=N'e272453d-7bd6-4d51-8ced-3b6d135c7c7a'; END ELSE BEGIN EXEC msdb.dbo.sp_update_job @job_id=@JobId, @new_name=N'Rebuild Indexes', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'vm-tanyo-app-pr\magnusminds', @notify_level_eventlog=0, @notify_level_email=2, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=N'DB Alerts', @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; END;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId) BEGIN SELECT TOP(1) @StepId=step_id FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId ORDER BY step_id DESC; EXEC msdb.dbo.sp_delete_jobstep @job_id=@JobId,@step_id=@StepId; END;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=1,@step_name=N'Rebuild All Indexes',@subsystem=N'TSQL',@command=N'DECLARE @FragmentationThreshold FLOAT = 70;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @Counter INT = 1;
DECLARE @Total INT;

SET NOCOUNT ON

DECLARE @RebuildQueries TABLE (
 ID INT IDENTITY(1,1),
 RebuildQuery NVARCHAR(MAX)
);

INSERT INTO @RebuildQueries (RebuildQuery)
SELECT ''ALTER INDEX ['' + I.name + ''] ON ['' + S.name + ''].['' + T.name + ''] REBUILD WITH (FILLFACTOR = 70);''
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
INNER JOIN sys.tables T ON T.object_id = DDIPS.object_id
INNER JOIN sys.schemas S ON T.schema_id = S.schema_id
INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
 AND DDIPS.index_id = I.index_id
WHERE DDIPS.database_id = DB_ID()
 AND I.name IS NOT NULL
 AND DDIPS.avg_fragmentation_in_percent >= @FragmentationThreshold   -- Filter based on the threshold
 AND I.is_primary_key = 0

--SELECT * FROM @RebuildQueries
--RETURN
SELECT @Total = COUNT(*) FROM @RebuildQueries;

WHILE @Counter <= @Total
BEGIN
 BEGIN TRY
  SELECT @SQL = RebuildQuery FROM @RebuildQueries WHERE ID = @Counter;

  BEGIN TRAN Rebuild_Index
   --PRINT @SQL;
   EXEC sp_executesql @SQL;
  COMMIT TRAN Rebuild_Index
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0
  BEGIN
   ROLLBACK TRAN Rebuild_Index
   SET @Counter = @Counter + 1;
   CONTINUE;
  END
 END CATCH
 SET @Counter = @Counter + 1;
END',@database_name=N'master',@database_user_name=NULL,@on_success_action=1,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId) BEGIN SELECT TOP(1) @ScheduleId=schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId ORDER BY schedule_id DESC; EXEC msdb.dbo.sp_detach_schedule @job_id=@JobId,@schedule_id=@ScheduleId; END;
SET @ScheduleId=NULL; SET @ExistingScheduleId=NULL; SET @AttachedJobCount=0; SELECT @ExistingScheduleId=schedule_id FROM msdb.dbo.sysschedules WHERE name=N'Monday 6 AM'; IF @ExistingScheduleId IS NOT NULL BEGIN SELECT @AttachedJobCount=COUNT(*) FROM msdb.dbo.sysjobschedules WHERE schedule_id=@ExistingScheduleId; IF @AttachedJobCount>0 THROW 51000,'Cannot update shared SQL Agent schedule; refusing to change another job.',1; SET @ScheduleId=@ExistingScheduleId; EXEC msdb.dbo.sp_update_schedule @schedule_id=@ScheduleId,@name=N'Monday 6 AM',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_subday_interval=0,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20250910,@active_end_date=99991231,@active_start_time=60000,@active_end_time=235959; END ELSE BEGIN EXEC msdb.dbo.sp_add_schedule @schedule_id=@ScheduleId OUTPUT,@schedule_name=N'Monday 6 AM',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20250910,@active_end_date=99991231,@active_start_time=60000,@active_end_time=235959; END; EXEC msdb.dbo.sp_attach_schedule @job_id=@JobId,@schedule_id=@ScheduleId;
SET @ServerName=N'vm-tanyo-app-pr'; IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysjobservers WHERE job_id=@JobId AND server_id=(SELECT srvid FROM master.dbo.sysservers WHERE srvname=@ServerName)) EXEC msdb.dbo.sp_add_jobserver @job_id=@JobId,@server_name=@ServerName;
