-- Job: DBA - Backup DB Weekly (4afbaa76-3b91-4ad5-b071-77586d4362f7)
USE [msdb];
SET NOCOUNT ON;
DECLARE @JobId uniqueidentifier; DECLARE @StepId int; DECLARE @ScheduleId int; DECLARE @ExistingScheduleId int; DECLARE @AttachedJobCount int; DECLARE @ServerName sysname; DECLARE @ExistingServerName sysname;
SELECT @JobId=job_id FROM msdb.dbo.sysjobs WHERE name=N'DBA - Backup DB Weekly'; IF @JobId IS NULL BEGIN EXEC msdb.dbo.sp_add_job @job_id=N'4afbaa76-3b91-4ad5-b071-77586d4362f7', @job_name=N'DBA - Backup DB Weekly', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'parshwa', @notify_level_eventlog=0, @notify_level_email=0, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=NULL, @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; SET @JobId=N'4afbaa76-3b91-4ad5-b071-77586d4362f7'; END ELSE BEGIN EXEC msdb.dbo.sp_update_job @job_id=@JobId, @new_name=N'DBA - Backup DB Weekly', @enabled=1, @description=N'No description available.', @start_step_id=1, @category_name=N'[Uncategorized (Local)]', @owner_login_name=N'parshwa', @notify_level_eventlog=0, @notify_level_email=0, @notify_level_netsend=0, @notify_level_page=0, @notify_email_operator_name=NULL, @notify_page_operator_name=NULL, @notify_netsend_operator_name=NULL, @delete_level=0; END;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId) BEGIN SELECT TOP(1) @StepId=step_id FROM msdb.dbo.sysjobsteps WHERE job_id=@JobId ORDER BY step_id DESC; EXEC msdb.dbo.sp_delete_jobstep @job_id=@JobId,@step_id=@StepId; END;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=1,@step_name=N'Delete Old Backup',@subsystem=N'TSQL',@command=N'EXEC dbo.DeleteLogOldBackups',@database_name=N'master',@database_user_name=NULL,@on_success_action=3,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=2,@step_name=N'Backup Database',@subsystem=N'TSQL',@command=N'EXEC dbo.CreateLogDatabaseBackupDaily',@database_name=N'master',@database_user_name=NULL,@on_success_action=3,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
EXEC msdb.dbo.sp_add_jobstep @job_id=@JobId,@step_id=3,@step_name=N'Upload files to Azure Blob',@subsystem=N'PowerShell',@command=N'# Define variables
$connectionString = "DefaultEndpointsProtocol=https;AccountName=tanyocrm;AccountKey=REMOVED_CREDENTIAL;EndpointSuffix=core.windows.net"
$containerName = "database-backup"
$folderPath = "D:\Database\Backup\LogDB"

# Import Azure Storage module
Import-Module Az.Storage

# Create the storage account context using the connection string
$storageAccountContext = New-AzStorageContext -ConnectionString $connectionString

# Ensure the container exists
$container = Get-AzStorageContainer -Name $containerName -Context $storageAccountContext -ErrorAction SilentlyContinue
if (-not $container) {
    Write-Output "Container ''$containerName'' does not exist. Creating it..."
    New-AzStorageContainer -Name $containerName -Context $storageAccountContext -Permission Off
} else {
    Write-Output "Container ''$containerName'' exists."
}

# Loop through each file in the folder and upload to Azure Blob Storage
Get-ChildItem -Path $folderPath -File | ForEach-Object {
    $filePath = $_.FullName
    $blobName = $_.Name

    # Check if the blob exists
    $existingBlob = Get-AzStorageBlob -Container $containerName -Blob $blobName -Context $storageAccountContext -ErrorAction SilentlyContinue
    if ($existingBlob) {
        Write-Output "Skipping $blobName - already exists in the container."
    } else {
        # Upload the file to Azure Blob Storage
        Write-Output "Uploading $blobName..."
        Set-AzStorageBlobContent -File $filePath -Container $containerName -Blob $blobName -Context $storageAccountContext
        Write-Output "$blobName uploaded successfully."
    }
}

Write-Output "File upload to Azure Blob Storage completed."
',@database_name=N'master',@database_user_name=NULL,@on_success_action=1,@on_success_step_id=0,@on_fail_action=2,@on_fail_step_id=0,@retry_attempts=0,@retry_interval=0,@cmdexec_success_code=0,@os_run_priority=0,@output_file_name=NULL,@flags=0,@proxy_name=NULL;
WHILE EXISTS(SELECT 1 FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId) BEGIN SELECT TOP(1) @ScheduleId=schedule_id FROM msdb.dbo.sysjobschedules WHERE job_id=@JobId ORDER BY schedule_id DESC; EXEC msdb.dbo.sp_detach_schedule @job_id=@JobId,@schedule_id=@ScheduleId; END;
SET @ScheduleId=NULL; SET @ExistingScheduleId=NULL; SET @AttachedJobCount=0; SELECT @ExistingScheduleId=schedule_id FROM msdb.dbo.sysschedules WHERE name=N'Weekly'; IF @ExistingScheduleId IS NOT NULL BEGIN SELECT @AttachedJobCount=COUNT(*) FROM msdb.dbo.sysjobschedules WHERE schedule_id=@ExistingScheduleId; IF @AttachedJobCount>0 THROW 51000,'Cannot update shared SQL Agent schedule; refusing to change another job.',1; SET @ScheduleId=@ExistingScheduleId; EXEC msdb.dbo.sp_update_schedule @schedule_id=@ScheduleId,@name=N'Weekly',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_subday_interval=0,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20250813,@active_end_date=99991231,@active_start_time=1500,@active_end_time=235959; END ELSE BEGIN EXEC msdb.dbo.sp_add_schedule @schedule_id=@ScheduleId OUTPUT,@schedule_name=N'Weekly',@enabled=1,@freq_type=8,@freq_interval=2,@freq_subday_type=1,@freq_relative_interval=0,@freq_recurrence_factor=1,@active_start_date=20250813,@active_end_date=99991231,@active_start_time=1500,@active_end_time=235959; END; EXEC msdb.dbo.sp_attach_schedule @job_id=@JobId,@schedule_id=@ScheduleId;
SET @ServerName=N'vm-tanyo-app-pr'; IF NOT EXISTS(SELECT 1 FROM msdb.dbo.sysjobservers WHERE job_id=@JobId AND server_id=(SELECT srvid FROM master.dbo.sysservers WHERE srvname=@ServerName)) EXEC msdb.dbo.sp_add_jobserver @job_id=@JobId,@server_name=@ServerName;
