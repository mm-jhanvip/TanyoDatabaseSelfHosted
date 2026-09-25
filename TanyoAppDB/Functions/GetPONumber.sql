-- =============================================
-- Author:		Parshwa Kapadia
-- Create date: 11-01-2025
-- Description:	Generate Purchase Order Number
-- =============================================
--SELECT dbo.GetPONumber(1)
CREATE   FUNCTION [dbo].[GetPONumber]
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

	DECLARE @PONumberGenerationType BIT = 0
		,@PONumberCounter BIGINT = 0

	SELECT @PONumberGenerationType = PONumberGenerationType
		,@PONumberCounter = PONumberCounter + 1
	FROM TenantConfigurations
	WHERE TenantId = @TenantID

	IF (@PONumberGenerationType = 1)
	BEGIN
		SELECT @Random = RIGHT('00000', 5 - LEN(CAST(@PONumberCounter AS VARCHAR(5)))) + CAST(@PONumberCounter AS VARCHAR(5))

		SELECT @PONumber = 'PO' + @Random + '-' + @PONumber
	END
	ELSE
	BEGIN
		SELECT	@Random = LEFT(ABS(CHECKSUM(RandomID)), 5)
		FROM GetRandomID

		SELECT @PONumber = 'PO' + @Random + '-' + @PONumber
	END
	--SELECT @inc = 0
	--	,@sum = 0

	--WHILE @inc <= LEN(@Random)
	--BEGIN
	--	SET @sum = @sum + CAST(SUBSTRING(@Random, @inc, 1) AS INT)
	--	SET @inc = @inc + 1
	--END


	IF EXISTS (
				SELECT po.POProductId
				FROM POProducts po WITH (NOLOCK)
				WHERE po.TenantId = @TenantID
				AND (po.PONumber = @PONumber OR LEFT(po.PONumber, 6) = 'PO' + @Random)
			)
	BEGIN
		SELECT @PONumber = dbo.GetPONumber(@TenantID)
	END

	RETURN @PONumber
END

GO

