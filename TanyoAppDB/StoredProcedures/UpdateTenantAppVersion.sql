-- =============================================
-- Author       : MagnusMinds
-- Create date  : 07-Aug-2026
-- Description  : Update Tenant App Version
-- =============================================
/*
    EXEC [dbo].[UpdateTenantAppVersion]
         @TenantAppVersionId = 1
        ,@DeviceType = 'Android'
        ,@AppVersion = '2.5.0'
        ,@IsForceUpdate = 1
        ,@IsMaintenance = 0
        ,@LastModifiedBy = 1
*/
CREATE PROCEDURE [dbo].[UpdateTenantAppVersion] (
	@TenantAppVersionId INT
	,@DeviceType VARCHAR(50)
	,@AppVersion VARCHAR(100)
	,@IsForceUpdate BIT
	,@IsMaintenance BIT
	,@LastModifiedBy BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- =============================================
		-- Validation
		-- =============================================
		IF ISNULL(@TenantAppVersionId, 0) <= 0
		BEGIN
			SELECT CAST(0 AS BIT) AS STATUS
				,'Invalid Tenant App Version Id.' AS Message;

			RETURN;
		END;

		IF NOT EXISTS (
				SELECT 1
				FROM [dbo].[TenantAppVersion] WITH (NOLOCK)
				WHERE TenantAppVersionId = @TenantAppVersionId
				)
		BEGIN
			SELECT CAST(0 AS BIT) AS STATUS
				,'Tenant app version record not found.' AS Message;

			RETURN;
		END;

		IF NULLIF(LTRIM(RTRIM(@DeviceType)), '') IS NULL
		BEGIN
			SELECT CAST(0 AS BIT) AS STATUS
				,'Device Type is required.' AS Message;

			RETURN;
		END;

		IF NULLIF(LTRIM(RTRIM(@AppVersion)), '') IS NULL
		BEGIN
			SELECT CAST(0 AS BIT) AS STATUS
				,'App Version is required.' AS Message;

			RETURN;
		END;

		-- =============================================
		-- Update
		-- =============================================
		UPDATE [dbo].[TenantAppVersion]
		SET DeviceType = LTRIM(RTRIM(@DeviceType))
			,AppVersion = LTRIM(RTRIM(@AppVersion))
			,IsForceUpdate = ISNULL(@IsForceUpdate, 0)
			,IsMaintenance = ISNULL(@IsMaintenance, 0)
			,LastModifiedBy = @LastModifiedBy
			,LastModifiedDate = SYSDATETIMEOFFSET()
			,LastModifiedUTCDate = GETUTCDATE()
		WHERE TenantAppVersionId = @TenantAppVersionId;

		SELECT CAST(1 AS BIT) AS STATUS
			,'Tenant app version updated successfully.' AS Message;
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

