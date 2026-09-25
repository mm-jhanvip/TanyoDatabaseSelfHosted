CREATE PROCEDURE [dbo].[SearchCustomer] (
	@Search NVARCHAR(100)
	,@TenantId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT CustomerId
			,FirstName
			,ISNULL(LastName, '') AS LastName
			,PhoneNumber
			,CustomerTypeId
		FROM Customers WITH (NOLOCK)
		WHERE IsDeleted = 0
			AND TenantId = @TenantId
			AND (
				@Search IS NULL
				OR @Search = 'null'
				OR REPLACE(LOWER(FirstName), ' ', '') LIKE '%' + REPLACE(LOWER(@Search), ' ', '') + '%'
				OR REPLACE(LOWER(ISNULL(LastName, '')), ' ', '') LIKE '%' + REPLACE(LOWER(@Search), ' ', '') + '%'
				OR REPLACE(LOWER(FirstName + ISNULL(LastName, '')), ' ', '') LIKE '%' + REPLACE(LOWER(@Search), ' ', '') + '%'
				OR PhoneNumber LIKE '%' + @Search + '%'
				)
		ORDER BY FirstName;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END;

GO

