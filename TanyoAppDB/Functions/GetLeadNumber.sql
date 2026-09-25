/*
SELECT dbo.GetLeadNumber(2)
*/

CREATE FUNCTION [dbo].[GetLeadNumber] (
	@TenantID BIGINT
	)
RETURNS VARCHAR(15)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @LeadNumber VARCHAR(15)

	--SELECT @LeadNumber = FORMAT(GETDATE(), 'ddMMyyyy')

	DECLARE @Random VARCHAR(5)
		,@inc INT
		,@sum INT
	DECLARE @LeadNumberCounter BIGINT = 0

	SELECT @LeadNumberCounter = LeadNumberCounter + 1
	FROM TenantConfigurations
	WHERE TenantId = @TenantID


	SELECT @Random = RIGHT('00000', 5 - LEN(CAST(@LeadNumberCounter AS VARCHAR(5)))) + CAST(@LeadNumberCounter AS VARCHAR(5))


	SELECT @LeadNumber = 'L' + @Random --+ '-' + @LeadNumber

	--IF EXISTS (
	--		SELECT LeadId
	--		FROM Leads L WITH (NOLOCK)
	--		WHERE L.TenantId = @TenantID
	--			AND (
	--				L.LeadNumber = @LeadNumber
	--				OR LEFT(L.LeadNumber, 6) = 'L' + @Random
	--				)
	--		)
	--BEGIN
	--	SELECT @LeadNumber = dbo.GetLeadNumber(@TenantID)
	--END

	RETURN @LeadNumber
END

GO

