-- =============================================
-- Author:		Parshwa Kapadia
-- Create date: 04-10-2022
-- Description:	Generate Master OTP by Tenant
-- =============================================
--SELECT dbo.GetMasterOTP(1)
CREATE FUNCTION [dbo].[GetMasterOTP]
(
	@TenantID BIGINT
)
RETURNS VARCHAR(4)
WITH ENCRYPTION
AS
BEGIN
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

	IF EXISTS (
				SELECT t.MasterOTP
				FROM Tenants t WITH (NOLOCK)
				WHERE t.TenantId = @TenantID
				AND (t.MasterOTP = @Random)
			)
	BEGIN
		SELECT @Random = dbo.GetMasterOTP(@TenantID)
	END

	RETURN @Random
END

GO

