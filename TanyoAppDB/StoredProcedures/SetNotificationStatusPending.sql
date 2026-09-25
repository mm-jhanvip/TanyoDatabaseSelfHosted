CREATE   PROCEDURE [dbo].[SetNotificationStatusPending]
	 @Status INT
	,@NotificationMethod VARCHAR(128)
WITH ENCRYPTION
AS
BEGIN
  BEGIN TRY
	SET NOCOUNT ON;

	UPDATE NM
	SET NM.Status = 0 
		,UpdatedBy = NM.CreatedBy
		,UpdatedDate = SYSDATETIMEOFFSET()
	FROM NotificationManagement NM
	INNER JOIN Tenants T ON T.TenantId = NM.TenantId
	WHERE T.EnableEmailNotification = 1
	AND NM.Status = @Status 
	AND NM.NotificationMethod = @NotificationMethod 
	AND T.IsDeleted = 0
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

