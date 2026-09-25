/*
	EXEC [dbo].[GetUnreadNotificationCount]
		@TenantId = 1
		,@SentTo = 100
		,@ApplicationType = 2
		,@FromDate = '2026-07-27'
*/
CREATE PROCEDURE [dbo].[GetUnreadNotificationCount] (
	@TenantId BIGINT
	,@SentTo BIGINT
	,@ApplicationType INT
	,@FromDate DATETIME
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT (
				SELECT COUNT(1)
				FROM [dbo].[Notifications] WITH (NOLOCK)
				WHERE [Notifications].TenantId = @TenantId
					AND [Notifications].SentTo = @SentTo
					AND [Notifications].IsRead = 0
					AND [Notifications].ApplicationType = @ApplicationType
					AND [Notifications].CreatedUTCDate > @FromDate
				) AS UnreadNotificationCount
			,(
				SELECT COUNT(1)
				FROM [dbo].[AnnouncementsUserMapping] WITH (NOLOCK)
				WHERE [AnnouncementsUserMapping].TenantId = @TenantId
					AND [AnnouncementsUserMapping].SentTo = @SentTo
					AND [AnnouncementsUserMapping].IsRead = 0
					AND [AnnouncementsUserMapping].ApplicationType = @ApplicationType
					AND [AnnouncementsUserMapping].CreatedUTCDate > @FromDate
				) AS UnreadAnnouncementCount;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMsg NVARCHAR(4000)
		DECLARE @ObjectName VARCHAR(500);

		SELECT @ErrorMsg = ERROR_MESSAGE()
			,@ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

