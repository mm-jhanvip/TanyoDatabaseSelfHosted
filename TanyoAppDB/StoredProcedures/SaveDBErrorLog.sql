CREATE PROC SaveDBErrorLog
(
	@ObjectName VARCHAR(500)
	,@ErrorMsg VARCHAR(MAX)
)
WITH ENCRYPTION
AS
BEGIN
	INSERT INTO DBErrorLogs(ObjectName, ErrorMessage)
	SELECT @ObjectName, @ErrorMsg
END

GO

