CREATE   FUNCTION [dbo].[GetProductSellPriceByDimension]
(
    @ProductId INT
    ,@TenantId BIGINT
    ,@Width DECIMAL(18, 2)
    ,@Height DECIMAL(18, 2)
    ,@Depth DECIMAL(18, 2)
    ,@CostPrice DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(18, 2) = 0;
    DECLARE @ProductWidth DECIMAL(18, 2);
    DECLARE @ProductHeight DECIMAL(18, 2);
    DECLARE @ProductDepth DECIMAL(18, 2);
    DECLARE @CategoryName NVARCHAR(255);
    DECLARE @TenantAmountRoundMultiple INT;
    DECLARE @CostPerCubic DECIMAL(18,6);
    DECLARE @TotalCubic DECIMAL(18, 2);
    DECLARE @NewCostPrice DECIMAL(18, 2);
    DECLARE @IsProduct BIT = 0;

    -- Fetch product data
    SELECT @ProductWidth = p.Width,
           @ProductHeight = p.Height,
           @ProductDepth = p.Depth,
           @CategoryName = (SELECT CategoryName FROM Categories WITH (NOLOCK) WHERE CategoryId = p.CategoryId)
    FROM Products p WITH (NOLOCK)
    WHERE p.ProductId = @ProductId
    AND p.TenantId = @TenantId

    -- Check if the category is a product category
    IF EXISTS (SELECT TOP 1 1
            FROM Categories c WITH (NOLOCK)
            WHERE c.CategoryName = @CategoryName
            AND c.TenantId = @TenantId
            AND c.CategoryTypeId = 1)
    BEGIN
        SET @IsProduct = 1
    END

    -- If not a product category, return price
    IF @IsProduct = 0
    BEGIN
        RETURN @CostPrice
    END

    -- Fetch tenant data
    SELECT @TenantAmountRoundMultiple = AmountRoundMultiple
    FROM Tenants WITH (NOLOCK)
    WHERE TenantId = @TenantId

	IF NULLIF(@ProductWidth,0) IS NULL
        SET @ProductWidth = 1;
	IF NULLIF(@ProductHeight,0) IS NULL
        SET @ProductHeight = 1;
	IF NULLIF(@ProductDepth,0) IS NULL
        SET @ProductDepth = 1;

	IF NULLIF(@Width,0) IS NULL
        SET @Width = 1;
	IF NULLIF(@Height,0) IS NULL
        SET @Height = 1;
	IF NULLIF(@Depth,0) IS NULL
        SET @Depth = 1;

    IF @TenantId = 1
    BEGIN
        -- Perform calculations based on category
        IF @CategoryName IN ('Sofa / Corner / Lounger', 'office sofa fix price')
        BEGIN
            SET @CostPerCubic = @CostPrice / @ProductWidth;
            SET @TotalCubic = @Width;
            SET @NewCostPrice = @TotalCubic * @CostPerCubic;
        END
        ELSE IF CHARINDEX('marble', @CategoryName) > 0
        BEGIN
            SET @CostPerCubic = @CostPrice / (@ProductWidth * @ProductDepth);
            SET @TotalCubic = @Width * @Depth;
            SET @NewCostPrice = @TotalCubic * @CostPerCubic;
        END
        ELSE
        BEGIN
            SET @NewCostPrice = @CostPrice
        END
    END
    ELSE
    BEGIN
        SET @CostPerCubic = @CostPrice / (@ProductWidth * @ProductHeight * @ProductDepth);
        SET @TotalCubic = @Width * @Height * @Depth;
        SET @NewCostPrice = @TotalCubic * @CostPerCubic;
    END

    -- Calculate rounded price
    RETURN ROUND(
        CASE 
            WHEN @TenantAmountRoundMultiple IS NOT NULL AND @TenantAmountRoundMultiple > 0 THEN 
                @TenantAmountRoundMultiple * ROUND(@NewCostPrice / @TenantAmountRoundMultiple, 2)
            ELSE 
                @NewCostPrice
        END, 2
    );
END

GO

