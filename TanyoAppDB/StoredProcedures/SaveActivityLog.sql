CREATE PROCEDURE [dbo].[SaveActivityLog] (
	@SubjectTypeId INT
	,@SubjectId BIGINT
	,@Description NVARCHAR(MAX)
	,@Action VARCHAR(50)
	,@CreatedBy INT
	,@CreatedDate DATETIMEOFFSET
	,@CreatedUTCDate DATETIME
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		INSERT INTO ActivityLogs (
			SubjectTypeId
			,SubjectId
			,Description
			,Action
			,CreatedBy
			,CreatedDate
			,CreatedUTCDate
			)
		VALUES (
			@SubjectTypeId
			,@SubjectId
			,@Description
			,@Action
			,@CreatedBy
			,@CreatedDate
			,@CreatedUTCDate
			);
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

