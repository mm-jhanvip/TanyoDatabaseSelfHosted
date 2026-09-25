/*
EXEC [dbo].[GetUsersWithFCMToken] @TenantId = 1207,@RoleName  = 'Administrator,Contractor'
*/
CREATE PROCEDURE [dbo].[GetUsersWithFCMToken] (
	@TenantId BIGINT
	,@RoleName VARCHAR(MAX) = 'Administrator,Contractor'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT DISTINCT U.UserId
			,REPLACE(R.Name, '_' + CAST(@TenantId AS VARCHAR(20)), '') AS UserRole
			,R.Id AS RoleId
			,U.RegisteredFCMToken
		FROM AspNetUsers U WITH (NOLOCK)
		INNER JOIN UserTenantMapping UTM WITH (NOLOCK) ON UTM.UserId = U.UserId
			AND UTM.TenantId = @TenantId
			AND UTM.IsDeleted = 0
		INNER JOIN AspNetUserRoles UR WITH (NOLOCK) ON UR.UserId = U.Id
		INNER JOIN AspNetRoles R WITH (NOLOCK) ON R.Id = UR.RoleId
			AND R.TenantId = @TenantId
		WHERE U.IsActive = 1
			AND ISNULL(LTRIM(RTRIM(U.RegisteredFCMToken)), '') <> ''
			AND EXISTS (
				SELECT 1
				FROM STRING_SPLIT(@RoleName, ',') spl
				WHERE LTRIM(RTRIM(spl.value)) <> ''
					AND R.Name LIKE '%' + LTRIM(RTRIM(spl.value)) + '%'
				);
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
		DECLARE @ObjectName VARCHAR(500)

		SET @ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

