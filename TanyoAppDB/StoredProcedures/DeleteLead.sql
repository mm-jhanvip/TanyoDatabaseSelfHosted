/*
	EXEC DeleteLead @LeadId = 1, @TenantId = 0
*/
CREATE PROC DeleteLead
(
	@LeadId BIGINT
	,@TenantId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SubjectTypeId BIGINT

	SELECT @SubjectTypeId = SubjectTypeId
	FROM SubjectTypes
	WHERE TenantId = @TenantId
	AND SubjectTypeName = 'Inquiries'

	DELETE FROM Notifications WHERE EntityTypeId = @SubjectTypeId AND EntityId = @LeadId
	DELETE FROM [dbo].[LeadRemarks] WHERE LeadId = @LeadId
	DELETE FROM [dbo].[LeadLogs] WHERE LeadId = @LeadId
	DELETE FROM [dbo].[LeadComments] WHERE LeadId = @LeadId
	DELETE FROM [dbo].[LeadAudios] WHERE LeadId = @LeadId
	DELETE FROM [dbo].[FollowUpLeads] WHERE LeadId = @LeadId
	DELETE FROM [dbo].[Leads] WHERE LeadId = @LeadId

END

GO

