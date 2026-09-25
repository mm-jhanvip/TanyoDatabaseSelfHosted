CREATE FUNCTION dbo.Levenshtein (
    @s1 NVARCHAR(100),
    @s2 NVARCHAR(100)
)
RETURNS INT
WITH ENCRYPTION
AS
BEGIN
    DECLARE @lenS1 INT = LEN(@s1),
            @lenS2 INT = LEN(@s2),
            @i INT,
            @j INT,
            @cost INT;
 
    DECLARE @d TABLE (
        i INT,
        j INT,
        val INT,
        PRIMARY KEY (i, j)
    );
 
    -- Initialize
    SET @i = 0;
    WHILE @i <= @lenS1
    BEGIN
        INSERT INTO @d (i, j, val) VALUES (@i, 0, @i);
        SET @i += 1;
    END
 
    SET @j = 1;
    WHILE @j <= @lenS2
    BEGIN
        INSERT INTO @d (i, j, val) VALUES (0, @j, @j);
        SET @j += 1;
    END
 
    -- Compute
    SET @i = 1;
    WHILE @i <= @lenS1
    BEGIN
        SET @j = 1;
        WHILE @j <= @lenS2
        BEGIN
            SET @cost = CASE 
                            WHEN SUBSTRING(@s1, @i, 1) = SUBSTRING(@s2, @j, 1) THEN 0 
                            ELSE 1 
                        END;
 
            INSERT INTO @d (i, j, val)
            SELECT 
                @i,
                @j,
                MIN(v)
            FROM (
                SELECT val + 1 AS v FROM @d WHERE i = @i - 1 AND j = @j
                UNION ALL
                SELECT val + 1 AS v FROM @d WHERE i = @i AND j = @j - 1
                UNION ALL
                SELECT val + @cost AS v FROM @d WHERE i = @i - 1 AND j = @j - 1
            ) AS x;
            SET @j += 1;
        END
        SET @i += 1;
    END
 
    RETURN (
        SELECT val 
        FROM @d 
        WHERE i = @lenS1 AND j = @lenS2
    );
END

GO

