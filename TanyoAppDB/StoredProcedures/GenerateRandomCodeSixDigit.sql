CREATE   PROCEDURE dbo.GenerateRandomCodeSixDigit
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Code CHAR(6)
    SET @Code = CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) +
                CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) +
                CHAR(48 + ABS(CHECKSUM(NEWID())) % 10) +
                CHAR(65 + ABS(CHECKSUM(NEWID())) % 26) +
                CHAR(48 + ABS(CHECKSUM(NEWID())) % 10) +
                CHAR(65 + ABS(CHECKSUM(NEWID())) % 26)
    SELECT @Code AS GeneratedCode
END

GO

