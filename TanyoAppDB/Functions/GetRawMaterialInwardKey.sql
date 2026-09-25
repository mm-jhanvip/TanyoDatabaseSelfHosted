
-- =============================================  
-- Author:  MagnusMids
-- Create date: 30-Oct-2025
-- Description: Generate Raw Material Inward Key
-- =============================================  
--SELECT dbo.GetRawMaterialInwardKey('IN')
CREATE   FUNCTION [dbo].[GetRawMaterialInwardKey] (@Type VARCHAR(2))
RETURNS VARCHAR(16)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @InwardEntryNumber VARCHAR(16)

	SELECT @InwardEntryNumber = FORMAT(GETDATE(), 'ddMMyyyy')

	DECLARE @Random VARCHAR(5)
		,@inc INT
		,@sum INT

	SELECT @Random = LEFT(ABS(CHECKSUM(RandomID)), 5)
	FROM GetRandomID

	SELECT @inc = 0
		,@sum = 0

	WHILE @inc <= LEN(@Random)
	BEGIN
		SET @sum = @sum + CAST(SUBSTRING(@Random, @inc, 1) AS INT)
		SET @inc = @inc + 1
	END

	SELECT @InwardEntryNumber = @Type + @Random + '-' + @InwardEntryNumber

	IF EXISTS (
			SELECT InwardEntryNumber
			FROM RawMaterialInwardEntry c WITH (NOLOCK)
			WHERE c.InwardEntryNumber = @InwardEntryNumber
			)
	BEGIN
		SELECT @InwardEntryNumber = dbo.GetInwardKey(@Type)
	END

	RETURN @InwardEntryNumber
END

GO

