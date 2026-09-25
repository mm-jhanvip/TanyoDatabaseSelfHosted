Create   FUNCTION [dbo].[zCalculateFinalFabricPrice]
(
    @FabricId INT,
    @UpdatedFabricPrice DECIMAL(18, 2),
    @CustomerType INT,
    @RoleId NVARCHAR(50),
    @TenantId INT
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @HasWholesalerPrice BIT = 0;
    DECLARE @FabricUnitPrice DECIMAL(18, 2);
    DECLARE @TenantFabricWSPPercentage DECIMAL(18, 2);
    DECLARE @TenantFabricRSPPercentage DECIMAL(18, 2);
    DECLARE @RoundTo INT;
    DECLARE @UnitPrice DECIMAL(18, 2);
    DECLARE @CalculatePercentage DECIMAL(18, 2);
    DECLARE @FinalFabricPrice DECIMAL(18, 2);
	DECLARE @RetailerPrice DECIMAL(18, 2);
	DECLARE @WholesalerPrice DECIMAL(18, 2);

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

    -- Get product data
    SELECT @FabricUnitPrice = UnitPrice, @RetailerPrice = RetailerPrice, @WholesalerPrice = WholesalerPrice
    FROM Fabrics WITH (NOLOCK)
    WHERE FabricId = @FabricId;

    -- Calculate cost price
    IF (@UpdatedFabricPrice IS NOT NULL AND @UpdatedFabricPrice > 0)
	BEGIN
		
		-- Get tenant data
		SELECT @RoundTo = AmountRoundMultiple, @TenantFabricWSPPercentage = FabricWSPPercentage, @TenantFabricRSPPercentage = FabricRSPPercentage
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId;

        SET @UnitPrice = @UpdatedFabricPrice;

		-- Calculate percentage
		IF (@CustomerType = 1 OR @HasWholesalerPrice = 1) -- Assuming 1 is for wholesale customer type
			SET @CalculatePercentage = ISNULL(@TenantFabricWSPPercentage, 0);
		ELSE
			SET @CalculatePercentage = ISNULL(@TenantFabricRSPPercentage, 0);

		-- Calculate final cost price
		IF (@CalculatePercentage > 0)
			SET @FinalFabricPrice = @UnitPrice + (@UnitPrice * @CalculatePercentage / 100);
		ELSE
			SET @FinalFabricPrice = @UnitPrice;

		IF (@RoundTo > 0)
			SET @FinalFabricPrice = @RoundTo * ROUND(@FinalFabricPrice / @RoundTo, 0);
    
		SET @FinalFabricPrice = ROUND(@FinalFabricPrice, 0);
	END
    ELSE
    BEGIN
		IF (@CustomerType = 1 OR @HasWholesalerPrice = 1) -- Assuming 1 is for wholesale customer type
			SET @FinalFabricPrice = @WholesalerPrice
		ELSE
			SET @FinalFabricPrice = @RetailerPrice
	END

	RETURN @FinalFabricPrice;
END

GO

