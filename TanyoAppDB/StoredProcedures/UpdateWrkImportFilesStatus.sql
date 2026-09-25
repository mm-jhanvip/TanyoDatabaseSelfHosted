CREATE PROCEDURE [dbo].[UpdateWrkImportFilesStatus] (
	@WrkImportFileID BIGINT
	,@UserId INT
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN UpdateWrkImportFilesStatus

		DECLARE @Success INT
		DECLARE @Failed INT
		DECLARE @CurrentDate DATETIMEOFFSET = SYSDATETIME()
		DECLARE @DTUTC DATETIME = GETUTCDATE()
			,@Status INT
			,@Message VARCHAR(128) = ''

		SELECT @Success = SUM(CASE 
					WHEN Status = 2
						THEN 1
					ELSE 0
					END)
			,@Failed = SUM(CASE 
					WHEN Status = 3
						THEN 1
					ELSE 0
					END)
		FROM WrkProducts WITH (NOLOCK)
		WHERE WrkImportFileID = @WrkImportFileID

		UPDATE WrkImportFiles
		SET Success = ISNULL(@Success, 0)
			,Failed = ISNULL(@Failed, 0)
			,Status = 2
			,ProcessEndDate = @CurrentDate
			,UpdatedBy = @UserId
			,UpdatedDate = @CurrentDate
			,UpdatedUTCDate = @DTUTC
		WHERE WrkImportFileID = @WrkImportFileID

		COMMIT TRAN UpdateWrkImportFilesStatus;

		SET @Status = 1
		SET @Message = 'Work file status updated successfully.'

		SELECT @Status AS [Status]
			,@Message AS [Message]
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN UpdateWrkImportFilesStatus;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SET @Status = 0
		SET @Message = 'Work file status update failed.'

		SELECT @Status AS [Status]
			,@Message AS [Message]
	END CATCH
END

GO

