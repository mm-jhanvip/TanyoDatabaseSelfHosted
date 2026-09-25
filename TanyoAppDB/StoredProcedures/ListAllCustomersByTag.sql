

/*
	EXEC dbo.ListAllCustomersByTag
		@TenantId = 1
		,@TagId = 10018
*/
CREATE   PROC [dbo].[ListAllCustomersByTag]
(
	@TenantId BIGINT
	,@TagId BIGINT
)
WITH ENCRYPTION
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.CustomerId
		,c.CustomerTypeId
		,c.FirstName + ' ' + ISNULL(c.LastName, '') AS CustomerName
		,c.PhoneNumber
		,NULL AS CustomerTenantID
	FROM dbo.Customers c WITH (NOLOCK)
	WHERE c.IsDeleted = 0
	AND c.TenantId = @TenantId
	AND c.LabelId = @TagId
	ORDER BY 3
END

GO

