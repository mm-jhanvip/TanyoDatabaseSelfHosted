/*
EXEC dbo.SetNotificationStatus
    @NotificationManagementID = 1,
    @Status = 1,    -- Completed / Failed 
	@Response = '',
	@WAMessageId = NULL
*/
CREATE   PROCEDURE [dbo].[SetNotificationStatus]
(
	@NotificationManagementID BIGINT
	,@Status INT
	,@Response VARCHAR(MAX) = ''
	,@WAMessageId VARCHAR(80) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY

	UPDATE NotificationManagement
	SET Status = @Status
		,UpdatedDate = SYSDATETIMEOFFSET()
		,UpdatedUTCDate = GETUTCDATE()
		,UpdatedBy = CreatedBy
		,Response = @Response
		,WAMessageId = @WAMessageId
	WHERE NotificationManagementID = @NotificationManagementID;

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

