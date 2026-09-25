-- SQL Server Agent jobs extracted from msdb on 74.225.222.125,1983.
USE [msdb];
SET NOCOUNT ON;
:r .\DatabaseMail.sql
GO
:r .\SQLAgentJobs\DBA_-_Backup_DB_Daily.sql
GO
:r .\SQLAgentJobs\DBA_-_Backup_DB_Weekly.sql
GO
:r .\SQLAgentJobs\Populate_ProductOffer.sql
GO
:r .\SQLAgentJobs\Populate_Stock_Valuation.sql
GO
:r .\SQLAgentJobs\Rebuild_Indexes.sql
GO
:r .\SQLAgentJobs\Remove_Expired_Offers.sql
GO
:r .\SQLAgentJobs\SendClientStatistics.sql
GO
:r .\SQLAgentJobs\syspolicy_purge_history.sql
GO
:r .\SQLAgentJobs\Update_EndDate_at_EOD.sql
GO
:r .\SQLAgentJobs\Update_Payment_Due_Status.sql
GO
:r .\SQLAgentJobs\UT_Notification.sql
