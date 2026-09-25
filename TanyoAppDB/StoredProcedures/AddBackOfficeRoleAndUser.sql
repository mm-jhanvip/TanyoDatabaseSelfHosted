/*
    EXEC [dbo].[AddBackOfficeRoleAndUser]
    @RoleName = 'BackOfficeUser'
    ,@NormalizedName = 'BackOfficeUser'
    ,@FirstName = 'Back Office'
    ,@LastName = 'Admin'
    ,@UserName = 'BackOfficeadmin@gmail.com'
    ,@NormalizedUserName = 'BackOfficeadmin@gmail.com'
    ,@Email = 'BackOfficeadmin@gmail.com' 
    ,@NormalizedEmail = 'BackOfficeadmin@gmail.com'
    ,@PasswordHash = 'AQAAAAEAACcQAAAAEMYMogeJQzjMFMqWz2bfrm6ZxmSBCAzA0bbaZQgC4P4QImS/JJpYEBYyTqOBnaH1Jw=='
    ,@PhoneNumber = '740569454
*/
CREATE PROCEDURE [dbo].[AddBackOfficeRoleAndUser]
(
@RoleName VARCHAR(100)
,@NormalizedName VARCHAR(100)
,@FirstName VARCHAR(50)
,@LastName VARCHAR(50)
,@UserName VARCHAR(100)
,@NormalizedUserName VARCHAR(100)
,@Email VARCHAR(100)
,@NormalizedEmail VARCHAR(100)
,@PasswordHash VARCHAR(100)
,@PhoneNumber VARCHAR(20)
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

    BEGIN TRY

    BEGIN TRAN
    DECLARE @RoleId VARCHAR(MAX) 
    ,@ConcurrencyStamp VARCHAR(MAX) 
    ,@AspNetUserId VARCHAR(MAX) 
    ,@SecurityStamp VARCHAR(MAX) 
    ,@PhoneNumberConfirmed bit = 0
    ,@TwoFactorEnabled bit = 0
    ,@LockoutEnabled bit = 0
    ,@AccessFailedCount bit = 0
    ,@IsActive bit = 1
    ,@IsDeleted bit = 0
    ,@EmailConfirmed bit = 1

      SELECT @RoleId = NEWID()
      SELECT @ConcurrencyStamp = NEWID()
      SELECT @AspNetUserId = NEWID()
      SELECT @SecurityStamp = NEWID()
--------- INSERT INTO ASPNETROLES TABLE ----------- 
    IF NOT EXISTS (
                SELECT 1
                FROM AspNetRoles
                WHERE LOWER(Name)  = LOWER(@RoleName)
                ) 
    BEGIN

        INSERT INTO AspNetRoles
                    (
                        Id
                        ,Name
                        ,NormalizedName
                        ,ConcurrencyStamp
                        )
                    SELECT
                        @RoleId 
                        ,@RoleName
                        ,@NormalizedName
                        ,@ConcurrencyStamp

    PRINT 'Role Created Successfully'
    END
--------- INSERT INTO ASPNETROLES TABLE ----------- 

     IF NOT EXISTS (
                SELECT 1
                FROM AspNetUsers
                WHERE Email = @Email 
                OR PhoneNumber = @PhoneNumber
                ) 

        INSERT INTO AspNetUsers
                    (
                        Id
                        ,FirstName
                        ,LastName
                        ,UserName
                        ,NormalizedUserName
                        ,Email
                        ,NormalizedEmail
                        ,EmailConfirmed
                        ,PasswordHash
                        ,IsActive
                        ,IsDeleted
                        ,PhoneNumber
                        ,PhoneNumberConfirmed
                        ,TwoFactorEnabled
                        ,LockoutEnabled
                        ,AccessFailedCount
                        ,SecurityStamp
                        ,ConcurrencyStamp
                    )
                    SELECT @AspNetUserId
                        ,@FirstName
                        ,@LastName
                        ,@UserName
                        ,UPPER(@NormalizedUserName)
                        ,@Email
                        ,UPPER(@Email)
                        ,@EmailConfirmed
                        ,@PasswordHash
                        ,@IsActive
                        ,@IsDeleted
                        ,@PhoneNumber
                        ,@PhoneNumberConfirmed
                        ,@TwoFactorEnabled
                        ,@LockoutEnabled
                        ,@AccessFailedCount
                        ,@SecurityStamp
                        ,@ConcurrencyStamp


        PRINT 'User Created Successfully'

------- INSERT INTO AspNetUserRoles Table --------

        INSERT INTO AspNetUserRoles
                    (
                        UserId
                        ,RoleId
                    )
                    SELECT @AspNetUserId
                        ,@RoleId
    COMMIT TRAN
    END TRY
    BEGIN CATCH
		    IF @@TRANCOUNT > 0
			    ROLLBACK

		    DECLARE @ErrorMessage NVARCHAR(4000)
		    DECLARE @ErrorSeverity INT
		    DECLARE @ErrorState INT
            DECLARE @ObjectName VARCHAR(500)

		    SELECT @ErrorMessage = ERROR_MESSAGE()
			    ,@ErrorSeverity = ERROR_SEVERITY()
			    ,@ErrorState = ERROR_STATE()
            
		     SET @ObjectName = OBJECT_NAME(@@PROCID)
		    

		    EXEC dbo.SaveDBErrorLog
			    @ObjectName = @ObjectName
			    ,@ErrorMsg = @ErrorMessage

	END CATCH
END

GO

