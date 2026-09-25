CREATE   PROCEDURE dbo.GetReferalCode(@ReferalCode CHAR(6) OUTPUT)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @NewCode CHAR(6)

    -- Generate a unique code
    WHILE 1 = 1
    BEGIN
        DECLARE @GeneratedCode TABLE (GeneratedCode CHAR(6))
        INSERT INTO @GeneratedCode EXEC dbo.GenerateRandomCodeSixDigit
        SELECT TOP 1 @ReferalCode = GeneratedCode FROM @GeneratedCode

        -- Check if the code is already used
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Tenants WHERE ReferalCode = @NewCode
        )
        BEGIN
            BREAK
        END
    END
END

GO

