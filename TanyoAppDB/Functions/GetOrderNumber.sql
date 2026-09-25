/*
SELECT dbo.GetOrderNumber('R', 1)
*/

CREATE FUNCTION [dbo].[GetOrderNumber] (
	@Type VARCHAR(2)
	,@TenantID BIGINT
	)
RETURNS VARCHAR(15)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @OrderNumber VARCHAR(15)

	SELECT @OrderNumber = FORMAT(GETDATE(), 'ddMMyyyy')

	DECLARE @Random VARCHAR(5)
		,@inc INT
		,@sum INT
	DECLARE @OrderNumberGenerationType BIT = 0
		,@OrderNumberCounter BIGINT = 0

	SELECT @OrderNumberGenerationType = OrderNumberGenerationType
		,@OrderNumberCounter = OrderNumberCounter + 1
	FROM TenantConfigurations
	WHERE TenantId = @TenantID

	IF (@OrderNumberGenerationType = 1)
	BEGIN
		SELECT @Random = RIGHT('00000', 5 - LEN(CAST(@OrderNumberCounter AS VARCHAR(5)))) + CAST(@OrderNumberCounter AS VARCHAR(5))
	END
	ELSE
	BEGIN
		SELECT @Random = LEFT(ABS(CHECKSUM(RandomID)), 5)
		FROM GetRandomID
	END

	--SELECT @inc = 0
	--	,@sum = 0

	--WHILE @inc <= LEN(@Random)
	--BEGIN
	--	SET @sum = @sum + CAST(SUBSTRING(@Random, @inc, 1) AS INT)
	--	SET @inc = @inc + 1
	--END

	SELECT @OrderNumber = @Type + @Random + '-' + @OrderNumber

	IF EXISTS (
			SELECT OrderID
			FROM Orders o WITH (NOLOCK)
			WHERE o.TenantId = @TenantID
				AND (
					o.OrderNo = @OrderNumber
					OR LEFT(o.OrderNo, 6) = @Type + @Random
					)
			)
	BEGIN
		SELECT @OrderNumber = dbo.GetOrderNumber(@Type, @TenantID)
	END

	RETURN @OrderNumber
END

GO

