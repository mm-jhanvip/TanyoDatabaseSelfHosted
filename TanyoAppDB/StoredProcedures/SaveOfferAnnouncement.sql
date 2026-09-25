/*
EXEC [dbo].[SaveOfferAnnouncement]
    @OfferId = 3338,
    @TenantId = 1206,
    @UserId = 1;
*/
CREATE PROCEDURE [dbo].[SaveOfferAnnouncement] (
	@OfferId BIGINT
	,@TenantId BIGINT
	,@UserId BIGINT
	,@IsPublished BIT = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DateNow DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@DateUtcNow DATETIME = GETUTCDATE()
		,@OfferCode NVARCHAR(100)
		,@OfferTitle NVARCHAR(200)
		,@OfferDisplayTitle NVARCHAR(200)
		,@AnnouncementId BIGINT
		,@RoleSuffix NVARCHAR(50) = '_' + CAST(@TenantId AS NVARCHAR(20))
		,@SalesRepRole NVARCHAR(50) = 'salesrepresentative'
		,@AdminRole NVARCHAR(50) = 'administrator'
		,@OfferPercentage DECIMAL(5, 2)
		,@OfferSubjectTypeId BIGINT
		,@LogDescription NVARCHAR(MAX)
		,@AnnouncementMessage NVARCHAR(MAX)
		,@Action NVARCHAR(50);;

	BEGIN TRY
		-- Fetch offer details
		SELECT @OfferCode = OfferCode
			,@OfferTitle = OfferTitle
			,@OfferPercentage = OfferPercentage
		FROM dbo.Offers WITH (NOLOCK)
		WHERE OfferId = @OfferId;

		SELECT @OfferSubjectTypeId = SubjectTypeId
		FROM dbo.SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Offer'
			AND TenantId = @TenantId;

		SET @OfferDisplayTitle = CASE 
				WHEN ISNULL(LTRIM(RTRIM(@OfferTitle)), '') = ''
					THEN LTRIM(RTRIM(@OfferCode))
				ELSE LTRIM(RTRIM(@OfferTitle))
				END;

		BEGIN TRAN SaveOfferAnnouncement

		-- Set Announcement Message & Activity Log based on @IsPublished
		IF @IsPublished = 0
		BEGIN
			SET @AnnouncementMessage = 'Hey! Offer ''' + @OfferDisplayTitle + ''' has been removed.';
			SET @LogDescription = 'Offer Removed ' + ISNULL(@OfferCode, '') + ' ' + CAST(ISNULL(@OfferPercentage, 0) AS NVARCHAR(20)) + '%.';
			SET @Action = 'Remove';
		END
		ELSE
		BEGIN
			SET @AnnouncementMessage = 'Hey! A new offer ''' + @OfferDisplayTitle + ''' has been added on products. Please check it out.';
			SET @LogDescription = 'Offer Applied ' + ISNULL(@OfferCode, '') + ' ' + CAST(ISNULL(@OfferPercentage, 0) AS NVARCHAR(20)) + '%.';
			SET @Action = 'Create';
		END

		-- 1. Insert Announcement
		INSERT INTO dbo.Announcements (
			Message
			,TenantId
			,CreatedBy
			,CreatedDate
			,CreatedUTCDate
			)
		VALUES (
			--'Hey! A new offer ''' + @OfferDisplayTitle + ''' has been added on products. Please check it out.'
			@AnnouncementMessage
			,@TenantId
			,@UserId
			,@DateNow
			,@DateUtcNow
			);

		SET @AnnouncementId = SCOPE_IDENTITY();

		-- 2. Insert User Mapping
		INSERT INTO dbo.AnnouncementsUserMapping (
			AnnouncementId
			,NotificationType
			,IsRead
			,SentTo
			,SentBy
			,TenantId
			,CreatedBy
			,CreatedDate
			,CreatedUTCDate
			,ApplicationType
			)
		SELECT DISTINCT @AnnouncementId
			,'Offers'
			,0
			,u.UserId
			,@UserId
			,@TenantId
			,@UserId
			,@DateNow
			,@DateUtcNow
			,2
		FROM dbo.AspNetUsers u WITH (NOLOCK)
		INNER JOIN dbo.UserTenantMapping utm WITH (NOLOCK) ON utm.UserId = u.UserId
			AND utm.TenantId = @TenantId
		INNER JOIN dbo.AspNetUserRoles ur WITH (NOLOCK) ON ur.UserId = u.Id
		INNER JOIN dbo.AspNetRoles r WITH (NOLOCK) ON r.Id = ur.RoleId
		WHERE u.IsActive = 1
			AND u.IsDeleted = 0
			AND r.Name IS NOT NULL
			AND LOWER(REPLACE(r.Name, @RoleSuffix, '')) IN (
				@SalesRepRole
				,@AdminRole
				);

		-- 3. Save Activity Log for each mapped product
		EXEC dbo.SaveActivityLog 
			 @SubjectTypeId = @OfferSubjectTypeId
			,@SubjectId = @OfferId
			,@Description = @LogDescription
			,@Action = @Action
			,@CreatedBy = @UserId
			,@CreatedDate = @DateNow
			,@CreatedUTCDate = @DateUtcNow;

		COMMIT TRAN SaveOfferAnnouncement;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SaveOfferAnnouncement;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog 
			 @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

