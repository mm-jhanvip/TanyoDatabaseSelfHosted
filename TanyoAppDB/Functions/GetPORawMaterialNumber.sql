-- =============================================
-- Author:		Parshwa Kapadia
-- Create date: 11-01-2025
-- Description:	Generate Purchase Order Number
-- =============================================
--SELECT dbo.GetPORawMaterialNumber(1)
CREATE     FUNCTION [dbo].[GetPORawMaterialNumber]
(
	@TenantID BIGINT
)
RETURNS VARCHAR(15)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @PONumber VARCHAR(15)

	SELECT @PONumber = FORMAT(GETDATE(), 'ddMMyy')

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

	SELECT @PONumber = 'RPO' + @Random + '-' + @PONumber

	IF EXISTS (
				SELECT po.PORawMaterialId
				FROM PORawMaterials po WITH (NOLOCK)
				WHERE po.TenantId = @TenantID
				AND (po.PONumber = @PONumber OR LEFT(po.PONumber, 6) = 'RPO' + @Random)
			)
	BEGIN
		SELECT @PONumber = dbo.GetPORawMaterialNumber(@TenantID)
	END

	RETURN @PONumber
END

GO

