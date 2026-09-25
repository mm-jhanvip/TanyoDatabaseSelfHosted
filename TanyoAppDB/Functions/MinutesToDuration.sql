CREATE FUNCTION [dbo].[MinutesToDuration]
(
    @minutes int 
)
RETURNS NVARCHAR(30)

WITH ENCRYPTION
AS
BEGIN
	DECLARE @hours  NVARCHAR(20)

	SET @hours = 
		CASE WHEN @minutes >= 60 THEN
			(SELECT IIF(LEN((@minutes / 60)) = 1, '0', '') + CAST((@minutes / 60) AS VARCHAR(2)) + ':' +
					CASE WHEN (@minutes % 60) > 0 THEN
						IIF(LEN((@minutes % 60)) = 1, '0', '') + CAST((@minutes % 60) AS VARCHAR(2))
					ELSE
						'00'
					END)
		ELSE 
			'00:' + IIF(LEN((@minutes % 60)) = 1, '0', '') + CAST((@minutes % 60) AS VARCHAR(2))
		END

	RETURN @hours
END

GO

