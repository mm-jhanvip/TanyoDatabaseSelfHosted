

-- =============================================
-- Author:		Nirav Desai
-- Create date: 17-02-2025
-- Description:	Generate Batch Number
-- =============================================
--SELECT dbo.GetBatchNumber(1)
CREATE     FUNCTION [dbo].[GetBatchNumber]
(
	@TenantID BIGINT
)
RETURNS VARCHAR(15)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @BatchNumber VARCHAR(15)

	SELECT @BatchNumber = FORMAT(GETDATE(), 'ddMMyyyy')

	DECLARE @Random VARCHAR(5), @inc INT, @sum INT

	SELECT	@Random = LEFT(ABS(CHECKSUM(RandomID)), 5)
	FROM GetRandomID

	SELECT @inc = 0
		,@sum = 0

	WHILE @inc <= LEN(@Random)
	BEGIN
		SET @sum = @sum + CAST(SUBSTRING(@Random, @inc, 1) AS INT)
		SET @inc = @inc + 1
	END

	SELECT @BatchNumber = 'B' + @Random + '-' + @BatchNumber

	IF EXISTS (
				SELECT ID
				FROM ProductShareBatch p WITH (NOLOCK)
				WHERE p.TenantId = @TenantID
				AND (p.BatchNo = @BatchNumber OR LEFT(p.BatchNo, 6) = 'B' + @Random)
			)
	BEGIN
		SELECT @BatchNumber = dbo.GetBatchNumber(@TenantID)
	END

	RETURN @BatchNumber
END

GO

