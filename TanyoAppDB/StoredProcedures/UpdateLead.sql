CREATE   PROCEDURE [dbo].[UpdateLead] (
	@LeadId BIGINT
	,@CustomerId BIGINT
	,@Status INT
	,@Inquiry NVARCHAR(MAX) = NULL
	,@SalesmanId BIGINT = NULL
	,@LeadSourceId BIGINT = NULL
	,@Other VARCHAR(MAX) = NULL
	,@InquiryAbout BIGINT = NULL
	,@InquiryFor NVARCHAR(500) = NULL
	,@LocationID BIGINT = NULL
	,@RefferedBy BIGINT = NULL
	,@PurchaseUrgencyId BIGINT = NULL
	,@CustomerBehaviorId BIGINT = NULL
	,@CloseLookupValueId INT = NULL
	,@TenantId BIGINT
	,@UserId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ReturnMessage VARCHAR(1024) = '';

	IF NOT EXISTS (
			SELECT 1
			FROM Leads WITH (NOLOCK)
			WHERE LeadId = @LeadId
				AND TenantId = @TenantId
				AND Status <> 6 -- Deleted 
			)
	BEGIN
		SET @ReturnMessage = 'Lead Not found';

		--RAISERROR(@ReturnMessage, 16, 1);
		--RETURN;
		THROW 50001
			,@ReturnMessage
			,1
	END

	IF @CustomerId IS NULL
		OR @CustomerId = 0
	BEGIN
		SET @ReturnMessage = 'Customer not found';

		--RAISERROR(@ReturnMessage, 16, 1);
		--RETURN;
		THROW 50001
			,@ReturnMessage
			,1
	END

	DECLARE @FirstName NVARCHAR(100)
		,@LastName NVARCHAR(100)
		,@PhoneNumber NVARCHAR(50)
		,@Email NVARCHAR(200);

	SELECT @FirstName = FirstName
		,@LastName = LastName
		,@PhoneNumber = PhoneNumber
		,@Email = EmailId
	FROM Customers WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
		AND TenantId = @TenantId
		and IsDeleted = 0;

	IF @FirstName IS NULL
	BEGIN
		SET @ReturnMessage = 'Customer not found';

		--RAISERROR(@ReturnMessage, 16, 1);
		--RETURN;
		THROW 50001
			,@ReturnMessage
			,1
	END

	DECLARE @OldSalesmanId BIGINT;

	SELECT @OldSalesmanId = SalesmanId
	FROM Leads WITH (NOLOCK)
	WHERE LeadId = @LeadId;

	IF @SalesmanId IS NOT NULL
		AND NOT EXISTS (
			SELECT 1
			FROM AspNetUsers AU WITH (NOLOCK)
			INNER JOIN UserTenantMapping UTM on au.UserId = utm.UserId 
			WHERE au.UserId = @SalesmanId
			and utm.TenantId = @TenantId
			and utm.IsDeleted = 0
			and au.IsDeleted = 0
			)
	BEGIN
		SET @SalesmanId = NULL;
	END

	IF @Status <> 5
		SET @CloseLookupValueId = NULL;

	DECLARE @dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@dtUTC DATETIME = GETUTCDATE();

	BEGIN TRANSACTION UpdateLead;

	BEGIN TRY
		UPDATE Leads
		SET CustomerId = @CustomerId
			,FirstName = @FirstName
			,LastName = @LastName
			,PhoneNumber = @PhoneNumber
			,Email = @Email
			,SalesmanId = @SalesmanId
			,LeadSourceId = @LeadSourceId
			,Notes = @Inquiry
			,InquiryAbout = @InquiryAbout
			,InquiryFor = @InquiryFor
			,RefferedBy = @RefferedBy
			,Other = @Other
			,Status = @Status
			,LocationID = CASE 
				WHEN ISNULL(@LocationID, 0) > 0
					THEN @LocationID
				ELSE LocationID
				END
			,CloseLookupValueId = @CloseLookupValueId
			,PurchaseUrgencyId = @PurchaseUrgencyId
			,CustomerBehaviorId = @CustomerBehaviorId
			,UpdatedBy = @UserId
			,UpdatedDate = @dt
			,UpdatedUTCDate = @dtUTC
		WHERE LeadId = @LeadId;

		IF (
				ISNULL(@OldSalesmanId, 0) <> ISNULL(@SalesmanId, 0)
				AND ISNULL(@SalesmanId, 0) > 0
				)
		BEGIN
			INSERT INTO LeadLogs (
				LeadId
				,SalesmanId
				,SentBy
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			VALUES (
				@LeadId
				,@SalesmanId
				,@UserId
				,@UserId
				,@dt
				,@dtUTC
				);
		END

		COMMIT TRANSACTION UpdateLead;

		SELECT l.LeadId
			,l.FirstName
			,l.LastName
			,l.Notes
			,l.PhoneNumber
			,l.SalesmanId
			,l.Other
			,l.Email
			,l.Priority
			,l.InquiryAbout
			,l.CustomerId
			,l.CloseLookupValueId
			,l.RefferedBy
			,l.InquiryFor
			,l.LeadSourceId
			,l.PurchaseUrgencyId
			,l.CustomerBehaviorId
		FROM Leads l WITH (NOLOCK)
		WHERE l.LeadId = @LeadId;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION UpdateLead;

	DECLARE @ObjectName VARCHAR(500)
	,@ErrorMsg VARCHAR(MAX);

	SET @ObjectName = OBJECT_NAME(@@PROCID);
	SET @ErrorMsg = ERROR_MESSAGE();

	EXEC dbo.SaveDBErrorLog 
	     @ObjectName = @ObjectName
		,@ErrorMsg = @ErrorMsg;

	END CATCH
END;

GO

