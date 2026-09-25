
CREATE FUNCTION [dbo].[CalculateTotalOfferAmount]
(
    @RetailerPrice DECIMAL(18, 2),
    @OfferPercentage DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @TotalOfferAmount DECIMAL(18, 2);
    DECLARE @OfferPrice DECIMAL(18, 2);

    -- Calculate the offer price
    SET @OfferPrice = (@RetailerPrice * @OfferPercentage) / 100;

    -- Calculate the total offer amount
    SET @TotalOfferAmount = @RetailerPrice - @OfferPrice;

    -- Round the total offer amount
    RETURN ROUND(@TotalOfferAmount, 2);
END

GO

