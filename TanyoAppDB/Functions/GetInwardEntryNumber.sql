/*
SELECT dbo.GetInwardEntryNumber(2)
*/

CREATE   FUNCTION [dbo].[GetInwardEntryNumber] (
    @TenantID BIGINT
)
RETURNS VARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @InwardEntryNumber VARCHAR(50)

  SELECT @InwardEntryNumber = FORMAT(GETDATE(), 'ddMMyyyy')

    DECLARE @InwardEntryNumberCounter BIGINT = 0

    SELECT @InwardEntryNumberCounter = ISNULL(InwardEntryNumberCounter, 0) + 1
    FROM TenantConfigurations
    WHERE TenantId = @TenantID

    DECLARE @FormattedCounter VARCHAR(10) = RIGHT('00000' + CAST(@InwardEntryNumberCounter AS VARCHAR(20)), 6)

    SET @InwardEntryNumber = 'IN' + @FormattedCounter + '-' + @InwardEntryNumber

    RETURN @InwardEntryNumber
END

GO

