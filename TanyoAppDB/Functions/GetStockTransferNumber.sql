
/*
SELECT dbo.GetStockTransferNumber(2)
*/

CREATE   FUNCTION [dbo].[GetStockTransferNumber] (
@TenantID BIGINT
)
RETURNS VARCHAR(15)
WITH ENCRYPTION
AS
BEGIN
DECLARE @StockTransferNumber VARCHAR(15)

SELECT @StockTransferNumber = FORMAT(GETDATE(), 'ddMMyyyy')

DECLARE @Random VARCHAR(5)
  ,@inc INT
  ,@sum INT
DECLARE @StockTransferNumberCounter BIGINT = 0

SELECT @StockTransferNumberCounter = StockTransferNumberCounter + 1
FROM TenantConfigurations
WHERE TenantId = @TenantID


SELECT @Random = RIGHT('0000'+ CAST(@StockTransferNumberCounter AS NVARCHAR(10)), 4);

SELECT @StockTransferNumber = 'ST' + @Random + '-' + @StockTransferNumber

RETURN @StockTransferNumber
END

GO

