







CREATE TRIGGER [SchemaMonitor] ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS AS

SET NOCOUNT ON

DECLARE @EventType NVARCHAR(MAX)
DECLARE @SchemaName NVARCHAR(MAX)
DECLARE @ObjectName NVARCHAR(MAX)
DECLARE @ObjectType NVARCHAR(MAX)
DECLARE @DBName VARCHAR(100)
DECLARE @Message VARCHAR(1000)
DECLARE @TSQL NVARCHAR(MAX)

BEGIN TRY


	SELECT @EventType = EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)')
		,@SchemaName = EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(max)')
		,@ObjectName = EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(max)')
		,@ObjectType = EVENTDATA().value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(max)')
		,@DBName = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)')
		,@TSQL = EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)')
	
	
	INSERT INTO [SQLObjectHistory] (
		[EventType]
		,[SchemaName]
		,[ObjectName]
		,[ObjectType]
		,[EventDate]
		,[SystemUser]
		,[CurrentUser]
		,[OriginalUser]
		,[DatabaseName]
		,[tsqlcode]
		,EventData
		)
	SELECT @EventType
		,@SchemaName
		,@ObjectName
		,@ObjectType
		,getdate()
		,SUSER_SNAME()
		,CURRENT_USER
		,ORIGINAL_LOGIN()
		,@DBName
		,@TSQL
		,EVENTDATA()

		IF @ObjectType <> 'INDEX' BEGIN 
			DECLARE @subject VARCHAR(MAX)
			SELECT @subject = 'Tanyo DB Schema updated for object: ' + @ObjectName + ' by ' + SUSER_SNAME()

			EXEC SendEmail 
					 @TenantId = 2
					 ,@ProfileName = 'DB EMail'
					,@RecipientEmail = 'tshah@MagnusMinds.net;parshwa@magnusminds.net;harsh@magnusminds.net'
					,@Subject = @subject
					,@Body = @TSQL
		END
END TRY

BEGIN CATCH
	DECLARE @msg VARCHAR(MAX)

	SELECT @msg = ERROR_MESSAGE()

	RAISERROR (
			'Error in SchemaMonitorFlow: %s'
			,16
			,1
			,@msg
			)
END CATCH

GO

