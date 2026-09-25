
CREATE   FUNCTION [dbo].[CalculateFinalCostPrice]
(
    @ProductId INT,
    @UpdatedCostPrice DECIMAL(18, 2),
    @CustomerType INT,
    @RoleId NVARCHAR(50),
    @TenantId INT,
    @CategoryId INT
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @HasWholesalerPrice BIT = 0;
    
    DECLARE @CategoryWSPPercentage DECIMAL(18, 2);
    DECLARE @CategoryRSPPercentage DECIMAL(18, 2);
    DECLARE @TenantWSPPercentage DECIMAL(18, 2);
    DECLARE @TenantRSPPercentage DECIMAL(18, 2);
    DECLARE @RoundTo INT;
    DECLARE @CostPrice DECIMAL(18, 2);
    DECLARE @CalculatePercentage DECIMAL(18, 2);
    DECLARE @FinalCostPrice DECIMAL(18, 2);
	

    -- Check if user has wholesaler price permission
    IF (@RoleId IS NOT NULL AND @RoleId <> '')
    BEGIN
        SELECT @HasWholesalerPrice = CASE WHEN EXISTS (
            SELECT 1 
            FROM AspNetRoleClaims WITH (NOLOCK)
            WHERE RoleId = @RoleId
            AND ClaimValue = 'Permissions.App.Order.WholeselerPrice'
        ) THEN 1 ELSE 0 END;
    END
    
	IF @CustomerType = 1 --wholesaler
		SET @HasWholesalerPrice = 1
    
    -- Calculate cost price
    IF (@UpdatedCostPrice IS NOT NULL AND @UpdatedCostPrice > 0)
	BEGIN
		
		-- Get category data
		SELECT @CategoryWSPPercentage = WSPPercentage, @CategoryRSPPercentage = RSPPercentage
		FROM Categories WITH (NOLOCK)
		WHERE CategoryId = @CategoryId;

		-- Get tenant data
		SELECT @RoundTo = AmountRoundMultiple, @TenantWSPPercentage = ProductWSPPercentage, @TenantRSPPercentage = ProductRSPPercentage
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId;

        SET @CostPrice = @UpdatedCostPrice;

		-- Calculate percentage
		IF (@HasWholesalerPrice = 1) -- Assuming 1 is for wholesale customer type
			SET @CalculatePercentage = CASE WHEN @CategoryWSPPercentage > 0 THEN @CategoryWSPPercentage ELSE ISNULL(@TenantWSPPercentage, 0) END;
		ELSE
			SET @CalculatePercentage = CASE WHEN @CategoryRSPPercentage > 0 THEN @CategoryRSPPercentage ELSE ISNULL(@TenantRSPPercentage, 0) END;

		-- Calculate final cost price
		IF (@CalculatePercentage > 0)
			SET @FinalCostPrice = @CostPrice + (@CostPrice * @CalculatePercentage / 100);
		ELSE
			SET @FinalCostPrice = @CostPrice;

		IF (@RoundTo > 0)
			SET @FinalCostPrice = @RoundTo * ROUND(@FinalCostPrice / @RoundTo, 0);
    
		SET @FinalCostPrice = ROUND(@FinalCostPrice, 0);
	END
    ELSE
    BEGIN
			DECLARE @ProductCostPrice DECIMAL(18, 2);
			DECLARE @RetailerPrice DECIMAL(18, 2);
			DECLARE @WholesalerPrice DECIMAL(18, 2);

			-- Get product data
			SELECT @ProductCostPrice = CostPrice, @RetailerPrice = RetailerPrice, @WholesalerPrice = WholesalerPrice
			FROM Products WITH (NOLOCK)
			WHERE ProductId = @ProductId;


		IF (@HasWholesalerPrice = 1) -- Assuming 1 is for wholesale customer type
			SET @FinalCostPrice = @WholesalerPrice
		ELSE
			SET @FinalCostPrice = @RetailerPrice
	END

	RETURN @FinalCostPrice;
END

GO

