/*

EXEC SendSMSNotification

*/
CREATE   PROCEDURE [dbo].[SendSMSNotification]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

	SELECT TOP 10 NM.NotificationManagementID
		,NM.TenantId
		,NM.ReceiverMobile
		,NM.NotificationType
		,NM.MessageSubject
		,NM.MessageBody
		,NM.CreatedDate
	FROM NotificationManagement NM WITH (NOLOCK)
	INNER JOIN Tenants T WITH (NOLOCK) ON T.TenantId = NM.TenantId
	WHERE T.EnableSMSNotification = 1
		AND NM.Status = 0 -- Pending
		AND T.IsDeleted = 0
		AND NM.NotificationMethod = 'SMS'
	ORDER BY NM.CreatedDate;

	END TRY

	BEGIN CATCH
	DECLARE @ObjectName VARCHAR(500)
		,@ErrorMsg VARCHAR(MAX);

	SET @ObjectName = OBJECT_NAME(@@PROCID);
	SET @ErrorMsg = ERROR_MESSAGE();

	EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
		,@ErrorMsg = @ErrorMsg;

	END CATCH
END

GO

