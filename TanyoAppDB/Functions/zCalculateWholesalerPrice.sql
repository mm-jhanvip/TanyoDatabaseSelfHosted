
CREATE   FUNCTION [dbo].[zCalculateWholesalerPrice]
(
    @ProductId INT
    ,@CategoryId INT
    ,@TenantId INT
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @CategoryWSPPercentage DECIMAL(18, 2);
    DECLARE @CategoryRSPPercentage DECIMAL(18, 2);
    DECLARE @TenantWSPPercentage DECIMAL(18, 2);
    DECLARE @TenantRSPPercentage DECIMAL(18, 2);
    DECLARE @RoundTo INT;
    DECLARE @CostPrice DECIMAL(18, 2);
    DECLARE @CalculatePercentage DECIMAL(18, 2);
    DECLARE @FinalCostPrice DECIMAL(18, 2);

	BEGIN
		
		-- Get category data
		SELECT @CategoryWSPPercentage = WSPPercentage, @CategoryRSPPercentage = RSPPercentage
		FROM Categories WITH (NOLOCK)
		WHERE CategoryId = @CategoryId;

		-- Get tenant data
		SELECT @RoundTo = AmountRoundMultiple, @TenantWSPPercentage = ProductWSPPercentage, @TenantRSPPercentage = ProductRSPPercentage
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId;

        SELECT @CostPrice = p.CostPrice
		FROM Products p WITH (NOLOCK)
		WHERE p.ProductId = @ProductId

		-- Calculate percentage
		SET @CalculatePercentage = CASE WHEN @CategoryWSPPercentage > 0 THEN @CategoryWSPPercentage ELSE ISNULL(@TenantWSPPercentage, 0) END;
		--SET @CalculatePercentage = CASE WHEN @CategoryRSPPercentage > 0 THEN @CategoryRSPPercentage ELSE ISNULL(@TenantRSPPercentage, 0) END;

		-- Calculate final cost price
		IF (@CalculatePercentage > 0)
			SET @FinalCostPrice = @CostPrice + (@CostPrice * @CalculatePercentage / 100);
		ELSE
			SET @FinalCostPrice = @CostPrice;

		IF (@RoundTo > 0)
			SET @FinalCostPrice = @RoundTo * ROUND(@FinalCostPrice / @RoundTo, 0);
    
		SET @FinalCostPrice = ROUND(@FinalCostPrice, 0);
	END

	RETURN @FinalCostPrice;
END

GO

