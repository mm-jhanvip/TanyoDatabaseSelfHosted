CREATE FUNCTION [dbo].[zGetUnitPriceWithoutOfferFormat]
(
    @TenantId INT,
    @CategoryName NVARCHAR(255),
    @ProductId INT,
    @InstantCostPrice DECIMAL(18, 2) = 1,
    @Width DECIMAL(18, 2) = 1,
    @Height DECIMAL(18, 2) = 1,
    @Depth DECIMAL(18, 2) = 1,
    @InstantWidth DECIMAL(18, 2) = 1,
    @InstantHeight DECIMAL(18, 2) = 1,
    @InstantDepth DECIMAL(18, 2) = 1,
    @AmountRoundMultiple INT,
    @Quantity DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @TotalPrice DECIMAL(18, 2);
    DECLARE @CostPerCubic DECIMAL(18, 2);
    DECLARE @NewCostPrice DECIMAL(18, 2);
    DECLARE @RetailerPrice DECIMAL(18, 2);
    DECLARE @TotalCubic DECIMAL(18, 2);
    DECLARE @CubicSize DECIMAL(18, 2);

    -- Default to 0 to avoid errors if conditions are not met
    SET @TotalPrice = 0;

    -- Category-specific logic
    IF (@TenantId = 1 OR @TenantId = 27)
    BEGIN
        IF (@CategoryName = 'Sofa / Corner / Lounger' OR @CategoryName = 'office sofa fix price')
        BEGIN
            -- Avoid division by zero
            IF (@InstantWidth = 0) SET @InstantWidth = 1;
			IF (@InstantCostPrice = 0) SET @InstantCostPrice = 1;

            SET @CostPerCubic = @InstantCostPrice / @InstantWidth;
            SET @TotalCubic = @Width;
            SET @NewCostPrice = @TotalCubic * @CostPerCubic;
            SET @NewCostPrice = ROUND(@NewCostPrice, 0);

            SET @RetailerPrice = dbo.CalculateFinalCostPrice(@ProductId, @NewCostPrice, 0, NULL, @TenantId, NULL);
            SET @TotalPrice = ROUND(@RetailerPrice * @Quantity, 2);
        END
        ELSE IF (CHARINDEX('marble', @CategoryName, 1) > 0)
        BEGIN
            -- Avoid division by zero
            IF (@InstantWidth = 0) SET @InstantWidth = 1;
            IF (@InstantDepth = 0) SET @InstantDepth = 1;
			IF (@InstantCostPrice = 0) SET @InstantCostPrice = 1;

            SET @CostPerCubic = @InstantCostPrice / (@InstantWidth * @InstantDepth);
            SET @TotalCubic = @Width * @Depth;
            SET @NewCostPrice = @TotalCubic * @CostPerCubic;
            SET @NewCostPrice = ROUND(@NewCostPrice, 0);

            SET @RetailerPrice = dbo.CalculateFinalCostPrice(@ProductId, @NewCostPrice, 0, NULL, @TenantId, NULL);
            SET @TotalPrice = ROUND(@RetailerPrice * @Quantity, 2);
        END
        ELSE
        BEGIN
            SET @TotalPrice = dbo.CalculateFinalCostPrice(@ProductId, 0, 0, NULL, @TenantId, NULL);
        END
    END
    ELSE
    BEGIN
        -- Avoid division by zero
        IF (@InstantWidth = 0) SET @InstantWidth = 1;
        IF (@InstantHeight = 0) SET @InstantHeight = 1;
        IF (@InstantDepth = 0) SET @InstantDepth = 1;
		IF (@InstantCostPrice = 0) SET @InstantCostPrice = 1;

        SET @CubicSize = @InstantWidth * @InstantHeight * @InstantDepth;
        IF (@CubicSize = 0) SET @CubicSize = 1; -- Avoid division by zero

        SET @CostPerCubic = @InstantCostPrice / @CubicSize;
        SET @TotalCubic = @Width * @Height * @Depth;
        SET @NewCostPrice = @TotalCubic * @CostPerCubic;

        SET @RetailerPrice = dbo.CalculateFinalCostPrice(@ProductId, @NewCostPrice, 0, NULL, @TenantId, NULL);
        SET @TotalPrice = ROUND(@RetailerPrice, 2);
    END

    RETURN @TotalPrice;
END

GO

