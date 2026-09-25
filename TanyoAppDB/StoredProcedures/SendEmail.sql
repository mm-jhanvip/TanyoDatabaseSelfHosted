/*
	EXEC SendEmail 
	 @TenantId = 2
	 ,@ProfileName = 'DB EMail'
	,@RecipientEmail = 'tshah@MagnusMinds.net'
	,@Subject = 'test subject notification for deactivation'
	,@Body = 'Body test'
	--,@Attachements = 'F:\BackOrderStatus.xls'
	,@CcEmail = NULL
	,@BccEmail = NULL
	
*/
CREATE PROCEDURE [dbo].[SendEmail] (
	@TenantId INT
	,@RecipientEmail VARCHAR(200)
	,@CcEmail VARCHAR(200) = NULL
	,@BccEmail VARCHAR(200) = NULL
	,@Subject VARCHAR(200)
	,@Body VARCHAR(MAX) = NULL
	,@Attachements VARCHAR(200) = NULL
	,@ProfileName VARCHAR(200) = NULL
	)

WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @EmailQuery VARCHAR(MAX)
		--SELECT TenantName FROM Tenants WHERE @TenantId=TenantId

		IF @ProfileName IS NULL
		BEGIN
			SELECT @ProfileName = 'DB EMail'
		END
		

		EXECUTE msdb..sp_send_dbmail 
			@profile_name = @ProfileName,
			@recipients = @RecipientEmail,
			@subject = @Subject,
			@copy_recipients = @CcEmail,
			@body_format = 'HTML',
			@body = @body,
			@blind_copy_recipients = @BccEmail,
			@file_attachments = @Attachements
		
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

