/*
	EXEC SearchLeadsByCustomerAndNotes
		@TenantId = 125
		,@CustomerId = 10
	    ,@Search = 'df'
*/
CREATE   PROCEDURE [dbo].[SearchLeadsByCustomerAndNotes]
(
	@TenantId INT
	,@CustomerId BIGINT
	,@Search NVARCHAR(500) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

	SELECT l.LeadId
		,ISNULL(l.Notes, '') AS LeadNotes
	FROM Leads AS l WITH (NOLOCK)
	WHERE l.CustomerId = @CustomerId
	AND l.TenantId = @TenantId
	AND l.Status <> 6 -- Lead Delete Status
	AND (ISNULL(@Search, '') = '' OR LOWER(l.Notes) LIKE '%' + LOWER(@Search) + '%')
	ORDER BY LeadNotes

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

