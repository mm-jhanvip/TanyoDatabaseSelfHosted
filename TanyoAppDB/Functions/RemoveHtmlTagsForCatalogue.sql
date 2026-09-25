CREATE FUNCTION [dbo].[RemoveHtmlTagsForCatalogue] (@InputText NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Start INT, @End INT, @Result NVARCHAR(MAX)
    SET @Result = REPLACE(REPLACE(@InputText,CHAR(13),CHAR(32)),CHAR(10),CHAR(32))

    -- Start searching for HTML tags
    SET @Start = CHARINDEX('<', @Result)
    WHILE @Start > 0
    BEGIN
        -- Find the closing tag
        SET @End = CHARINDEX('>', @Result, @Start)
        IF @End = 0
            BREAK

        -- Remove the tag (everything between < and >, inclusive)
        SET @Result = STUFF(@Result, @Start, @End - @Start + 1, '')

        -- Search for the next opening tag
        SET @Start = CHARINDEX('<', @Result)
    END

    -- Trim leading/trailing spaces
    SET @Result = LTRIM(RTRIM(@Result))

    -- Remove extra spaces between words
    WHILE CHARINDEX('  ', @Result) > 0
    BEGIN
        SET @Result = REPLACE(@Result, '  ', ' ') -- Replace double spaces with a single space
    END

    RETURN @Result
END

GO

