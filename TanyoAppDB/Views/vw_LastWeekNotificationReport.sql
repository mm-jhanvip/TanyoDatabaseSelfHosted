CREATE VIEW [dbo].[vw_LastWeekNotificationReport]
WITH ENCRYPTION
AS
SELECT NotificationType
	,CAST(CreatedDate AS DATE) NotificationDate
	,COUNT(NotificationManagementID) NotificationCount
FROM NotificationManagement WITH (NOLOCK)
WHERE CAST(CreatedDate AS DATE) BETWEEN DATEADD(DAY, - 7, CAST(GETDATE() AS DATE))
		AND CAST(GETDATE() AS DATE)
GROUP BY NotificationType
	,CAST(CreatedDate AS DATE)

GO

