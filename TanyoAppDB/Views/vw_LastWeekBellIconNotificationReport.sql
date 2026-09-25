CREATE VIEW [dbo].[vw_LastWeekBellIconNotificationReport]
WITH ENCRYPTION
AS
SELECT NotificationType
	,CAST(CreatedDate AS DATE) NotificationDate
	,COUNT(NotificationId) NotificationCount
FROM Notifications WITH (NOLOCK)
WHERE CAST(CreatedDate AS DATE) BETWEEN DATEADD(DAY, - 7, CAST(GETDATE() AS DATE))
		AND CAST(GETDATE() AS DATE)
GROUP BY NotificationType
	,CAST(CreatedDate AS DATE)

GO

