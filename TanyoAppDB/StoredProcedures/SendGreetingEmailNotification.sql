/*
	EXEC SendGreetingEmailNotification
*/
CREATE PROCEDURE [dbo].[SendGreetingEmailNotification]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT TOP 10 NM.NotificationManagementID
			,NM.TenantId
			,NM.ReceiverEmail
			,CASE 
				WHEN T.NotificationEmail IS NOT NULL
					AND NM.NotificationType IN (
						'Order'
						,'OrderApproved'
						,'OrderDeclined'
						,'OrderPendingForApproval'
						,'OrderInquiry'
						)
					THEN T.NotificationEmail
				ELSE NULL
				END AS NotificationEmail
			,NM.NotificationType
			,NM.MessageSubject
			,NM.MessageBody
			,NM.CreatedDate
		FROM NotificationManagement NM WITH (NOLOCK)
		INNER JOIN Tenants T WITH (NOLOCK) ON T.TenantId = NM.TenantId
			AND T.IsDeleted = 0
		WHERE T.EnableEmailNotification = 1
			AND NM.Status = 0 -- Pending
			AND NM.NotificationMethod = 'Email'
		ORDER BY NM.CreatedDate
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

