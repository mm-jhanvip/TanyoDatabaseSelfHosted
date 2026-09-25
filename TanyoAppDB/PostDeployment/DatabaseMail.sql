USE [msdb];
SET NOCOUNT ON;

DECLARE @AccountId INT;
DECLARE @ProfileId INT;
DECLARE @DatabaseMailPassword NVARCHAR(128) = N'$(DatabaseMailPassword)';

SELECT @AccountId = account_id
FROM dbo.sysmail_account
WHERE name = N'DB EMail SMTP';

IF @AccountId IS NULL
BEGIN
	IF @DatabaseMailPassword = N'__REQUIRED_DATABASE_MAIL_PASSWORD__'
		OR NULLIF(@DatabaseMailPassword, N'') IS NULL
	BEGIN
		THROW 50000, 'Database Mail account does not exist. Supply DatabaseMailPassword during deployment.', 1;
	END;

	EXEC dbo.sysmail_add_account_sp
		@account_name = N'DB EMail SMTP'
		,@description = NULL
		,@email_address = N'tanyoinnovations@gmail.com'
		,@display_name = N'Tanyo'
		,@replyto_address = NULL
		,@mailserver_name = N'smtp.gmail.com'
		,@mailserver_type = N'SMTP'
		,@port = 587
		,@username = N'tanyoinnovations@gmail.com'
		,@password = @DatabaseMailPassword
		,@use_default_credentials = 0
		,@enable_ssl = 1;

	SELECT @AccountId = account_id
	FROM dbo.sysmail_account
	WHERE name = N'DB EMail SMTP';
END
ELSE
BEGIN
	EXEC dbo.sysmail_update_account_sp
		@account_id = @AccountId
		,@account_name = N'DB EMail SMTP'
		,@description = NULL
		,@email_address = N'tanyoinnovations@gmail.com'
		,@display_name = N'Tanyo'
		,@replyto_address = NULL
		,@mailserver_name = N'smtp.gmail.com'
		,@mailserver_type = N'SMTP'
		,@port = 587
		,@username = N'tanyoinnovations@gmail.com'
		,@use_default_credentials = 0
		,@enable_ssl = 1;
END;

SELECT @ProfileId = profile_id
FROM dbo.sysmail_profile
WHERE name = N'DB EMail';

IF @ProfileId IS NULL
BEGIN
	EXEC dbo.sysmail_add_profile_sp
		@profile_name = N'DB EMail'
		,@description = NULL;

	SELECT @ProfileId = profile_id
	FROM dbo.sysmail_profile
	WHERE name = N'DB EMail';
END
ELSE
BEGIN
	EXEC dbo.sysmail_update_profile_sp
		@profile_id = @ProfileId
		,@profile_name = N'DB EMail'
		,@description = NULL;
END;

IF NOT EXISTS (
	SELECT 1
	FROM dbo.sysmail_profileaccount
	WHERE profile_id = @ProfileId
		AND account_id = @AccountId
)
BEGIN
	EXEC dbo.sysmail_add_profileaccount_sp
		@profile_name = N'DB EMail'
		,@account_name = N'DB EMail SMTP'
		,@sequence_number = 1;
END;
ELSE
BEGIN
	EXEC dbo.sysmail_update_profileaccount_sp
		@profile_name = N'DB EMail'
		,@account_name = N'DB EMail SMTP'
		,@sequence_number = 1;
END;

IF NOT EXISTS (
	SELECT 1
	FROM dbo.sysmail_principalprofile
	WHERE profile_id = @ProfileId
		AND principal_sid = 0x00
)
BEGIN
	EXEC dbo.sysmail_add_principalprofile_sp
		@profile_name = N'DB EMail'
		,@principal_name = N'public'
		,@is_default = 0;
END
ELSE
BEGIN
	EXEC dbo.sysmail_update_principalprofile_sp
		@profile_name = N'DB EMail'
		,@principal_name = N'public'
		,@is_default = 0;
END;