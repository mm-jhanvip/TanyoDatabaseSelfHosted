/*
	EXEC [dbo].[Job_GetFollowUpOrders]
*/
CREATE   PROC [dbo].[Job_GetFollowUpOrders]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @FollowUpDate DATETIME = DATEADD(HOUR, DATEDIFF(HOUR, 0, GETDATE()), 0)

	IF OBJECT_ID('tempdb..#OrderSubjectTypeByTenant') IS NOT NULL
		DROP TABLE #OrderSubjectTypeByTenant

	SELECT TenantID
		,SubjectTypeId
	INTO #OrderSubjectTypeByTenant
	FROM dbo.SubjectTypes st WITH (NOLOCK)
	WHERE st.SubjectTypeName = 'Orders'
		AND st.IsDeleted = 0

	INSERT INTO [dbo].[NotificationManagement] (
		EntityTypeID
		,EntityID
		,NotificationType
		,NotificationMethod
		,MessageSubject
		,ReceiverEmail
		,ReceiverMobile
		,STATUS
		,CreatedBy
		,TenantId
		,Response
		,MessageBody
		)
	SELECT OSTBT.SubjectTypeId AS EntityTypeId
		,o.OrderId AS EntityId
		,'Followup' AS NotificationType
		,'Email' AS NotificationMethod
		,'Reminder: Follow-up Task with ' + c.FirstName + ' ' + ISNULL(c.LastName, '') + ' (' + FORMAT(fuo.FollowUpDate, 'dd-MM-yyyy') + ', ' + FORMAT(fuo.FollowUpDate, 'hh:mm tt') + ')' AS MessageSubject
		,asp.Email AS ReceiverEmail
		,asp.PhoneNumber AS ReceiverMobile
		,0 AS [Status]
		,o.CreatedBy AS CreatedBy
		,o.TenantId
		,'' AS Response
		,N'<html>
		<head><title></title></head>
		<body style="font-family: Poppins, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0;">
			<div style="background-color: #ffffff; max-width: 600px; margin: 10px auto; border-radius: 8px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); overflow: hidden;">
				<div style="padding: 20px; text-align: left;">
					<p style="margin: 0; color: #333333;">Hello <b>' + asp.FirstName + ' ' + asp.LastName + '</b>,</p>
					<p style="color: #333333;">This is a reminder for your scheduled follow-up.</p>
					<table style="width: 100%; border-collapse: collapse; font-size: 14px; color: #111827; margin-top: 10px;">
						<tr>
							<td style="padding: 10px; border: 1px solid #e5e7eb; font-weight: 600; background-color: #f9fafb;">Follow-Up:</td>
							<td style="padding: 10px; border: 1px solid #e5e7eb;">' + fuo.FollowUpComment + 
		'</td>
						</tr>
						<tr>
							<td style="padding: 10px; border: 1px solid #e5e7eb; font-weight: 600; background-color: #f9fafb;">Date & Time:</td>
							<td style="padding: 10px; border: 1px solid #e5e7eb;">' + FORMAT(fuo.FollowUpDate, 'dd-MM-yyyy hh:mm tt') + '</td>
						</tr>
						<tr>
							<td style="padding: 10px; border: 1px solid #e5e7eb; font-weight: 600; background-color: #f9fafb;">Customer:</td>
							<td style="padding: 10px; border: 1px solid #e5e7eb;">' + c.FirstName + ' ' + ISNULL(c.LastName, '') + ' - ' + c.PhoneNumber + '</td>
						</tr>
					</table>
					<p style="color: #333333;">Please take necessary action.</p>
					<p style="color: #374151;">Regards,</p>
					<p style="color: #374151;">TANYO</p>
				</div>
			</div>
		</body>
		</html>' AS MessageBody
	FROM dbo.FollowUpOrders fuo WITH (NOLOCK)
	INNER JOIN dbo.Orders o WITH (NOLOCK) ON o.OrderId = fuo.OrderId
	INNER JOIN #OrderSubjectTypeByTenant OSTBT WITH (NOLOCK) ON OSTBT.TenantId = o.TenantId
	INNER JOIN dbo.AspNetUsers anu WITH (NOLOCK) ON anu.UserId = o.CreatedBy
	LEFT JOIN dbo.AspNetUsers asp WITH (NOLOCK) ON asp.UserId = o.SalesmanId
	LEFT JOIN dbo.Customers c WITH (NOLOCK) ON c.CustomerId = o.CustomerID
	WHERE o.STATUS <> 9
		AND o.IsArchive = 0
		AND DATEADD(HOUR, DATEDIFF(HOUR, 0, fuo.FollowUpDate), 0) = @FollowUpDate
		AND fuo.FollowUpDate IS NOT NULL
		AND ISNULL(fuo.FollowUpComment, '') <> ''

	INSERT INTO dbo.Notifications (
		EntityTypeId
		,EntityId
		,NotificationType
		,Message
		,IsRead
		,SentTo
		,SentBy
		,TenantId
		,CreatedBy
		,ApplicationType
		)
	SELECT OSTBT.SubjectTypeId AS EntityTypeId
		,o.OrderId AS EntityId
		,'Followup' AS NotificationType
		,ISNULL(fuo.FollowUpComment, 'Follow-up due at ' + FORMAT(fuo.FollowUpDate, 'hh:mm tt') + ', ' + FORMAT(fuo.FollowUpDate, 'dd-MM-yyyy') + '. Please check the inquiry for details.') AS Message
		,0 AS IsRead
		,o.SalesmanId AS SentTo
		,o.CreatedBy AS SentBy
		,o.TenantId AS TenantId
		,o.CreatedBy AS CreatedBy
		,2 AS ApplicationType
	FROM dbo.FollowUpOrders fuo WITH (NOLOCK)
	INNER JOIN dbo.Orders o WITH (NOLOCK) ON o.OrderId = fuo.OrderId
	INNER JOIN #OrderSubjectTypeByTenant OSTBT WITH (NOLOCK) ON OSTBT.TenantId = o.TenantId
	INNER JOIN AspNetUsers anu WITH (NOLOCK) ON anu.UserId = o.CreatedBy
	WHERE o.STATUS <> 9
		AND o.IsArchive = 0
		AND DATEADD(HOUR, DATEDIFF(HOUR, 0, fuo.FollowUpDate), 0) = @FollowUpDate
		AND fuo.FollowUpDate IS NOT NULL
		AND ISNULL(fuo.FollowUpComment, '') <> ''

	SELECT o.OrderId
		,o.OrderNo
		,CAST(fuo.FollowUpDate AS DATE) AS FollowUpDate
		,fuo.FollowUpComment
		,anu.RegisteredFCMToken
		,o.TenantId
		,T.TenantName
	FROM dbo.FollowUpOrders fuo WITH (NOLOCK)
	INNER JOIN dbo.Orders o WITH (NOLOCK) ON o.OrderId = fuo.OrderId
	INNER JOIN #OrderSubjectTypeByTenant OSTBT WITH (NOLOCK) ON OSTBT.TenantId = o.TenantId
	INNER JOIN Tenants T WITH (NOLOCK) ON T.TenantId = o.TenantId
		AND T.IsDeleted = 0
	INNER JOIN AspNetUsers anu WITH (NOLOCK) ON anu.UserId = o.SalesmanId
	WHERE o.STATUS <> 9
		AND o.IsArchive = 0
		AND DATEADD(HOUR, DATEDIFF(HOUR, 0, fuo.FollowUpDate), 0) = @FollowUpDate
		AND ISNULL(anu.RegisteredFCMToken, '') <> ''
		AND fuo.FollowUpDate IS NOT NULL
		AND ISNULL(fuo.FollowUpComment, '') <> ''
	END TRY
	BEGIN CATCH
	
	DECLARE @ObjectName VARCHAR(500)
		,@ErrorMsg VARCHAR(MAX)

	SET @ObjectName = OBJECT_NAME(@@PROCID)
	SET @ErrorMsg = ERROR_MESSAGE()

	EXEC dbo.SaveDBErrorLog
		@ObjectName = @ObjectName
		,@ErrorMsg = @ErrorMsg
	END CATCH
END

GO

