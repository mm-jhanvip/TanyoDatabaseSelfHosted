CREATE PROCEDURE [dbo].[SendNotificationToDeactiveTenants]
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		DECLARE @Date DATE = GETDATE()
		DECLARE @TenantId INT
			,@RecipientEmail VARCHAR(200)
			,@Subject VARCHAR(MAX)
			,@BodyMessage VARCHAR(MAX) = ''
		DECLARE @Tmp_DeactivatedTenants AS TABLE (
			Id INT IDENTITY(1, 1)
			,TenantId INT
			,DeactivateDate DATE
			,DeactivateDayCnt INT
			,BodyMessage VARCHAR(MAX)
			,RecipientEmail VARCHAR(200)
			,Subject VARCHAR(MAX)
			)
		DECLARE @Cnt BIGINT
			,@Inc BIGINT = 1;

		WITH Deactivatedtenant
		AS (
			SELECT TenantId
				,DeactiveDate
				,EmailId AS RecipientEmail
				,'Your Tenant ' + TenantName + ' is Deactivated' AS Subject
				,DATEDIFF(DAY, DeactiveDate, @Date) AS DeactivateDayCnt
				,'<p>Dear ' + TenantName + ',</p>
			<p>Your account is Deactivated for some reason. Please reach out on hello@tanyo.in to re-activate the same.</p>
			<p>Thanks,<br />Tanyo Team</p>' AS BodyMessage
			FROM Tenants
			WHERE IsDeleted = 1
				AND DeactiveDate >= DATEADD(DAY, - 11, @Date)
			)
		INSERT INTO @Tmp_DeactivatedTenants (
			TenantId
			,DeactivateDate
			,DeactivateDayCnt
			,BodyMessage
			,RecipientEmail
			,Subject
			)
		SELECT TenantId
			,DeactiveDate
			,DeactivateDayCnt
			,BodyMessage
			,RecipientEmail
			,Subject
		FROM Deactivatedtenant
		WHERE DeactivateDayCnt IN (3, 5, 10)

		SELECT *
		FROM @Tmp_DeactivatedTenants

		SELECT @Cnt = COUNT(1)
		FROM @Tmp_DeactivatedTenants

		WHILE (@Inc <= @Cnt)
		BEGIN
			SELECT @TenantId = NULL
				,@RecipientEmail = NULL
				,@Subject = NULL
				,@BodyMessage = NULL

			SELECT @TenantId = TenantId
				,@RecipientEmail = RecipientEmail
				,@Subject = Subject
				,@BodyMessage = BodyMessage
			FROM @Tmp_DeactivatedTenants

			EXEC SendEmail @TenantId = @TenantId
				,@RecipientEmail = @RecipientEmail
				,@Subject = @Subject
				,@Body = @BodyMessage
				--,@Attachements = 'F:\BackOrderStatus.xls'
				,@CcEmail = NULL
				,@BccEmail = NULL

			SET @Inc = @inc + 1;
		END
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

