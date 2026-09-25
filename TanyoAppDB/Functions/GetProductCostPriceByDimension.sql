CREATE FUNCTION [dbo].[GetProductCostPriceByDimension]
(
    @ProductId INT,
    @Width DECIMAL(18, 2),
    @Height DECIMAL(18, 2),
    @Depth DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @TotalAmount DECIMAL(18, 2) = 0;
    DECLARE @CostPrice DECIMAL(18, 2);
    DECLARE @ProductWidth DECIMAL(18, 2);
    DECLARE @ProductHeight DECIMAL(18, 2);
    DECLARE @ProductDepth DECIMAL(18, 2);
    DECLARE @CategoryName NVARCHAR(255);
    DECLARE @TenantAmountRoundMultiple INT;
    DECLARE @CostPerCubic DECIMAL(18, 2);
    DECLARE @TotalCubic DECIMAL(18, 2);
    DECLARE @NewCostPrice DECIMAL(18, 2);
    DECLARE @TenantId BIGINT;
    
    -- Fetch product data
    SELECT @CostPrice = IIF(p.CostPrice = 0, p.RetailerPrice, p.CostPrice)
           --,@CostPrice = CostPrice
           ,@ProductWidth = Width
           ,@ProductHeight = Height
           ,@ProductDepth = Depth
           ,@CategoryName = (SELECT CategoryName FROM Categories WHERE CategoryId = p.CategoryId)
           ,@TenantId = p.TenantId
    FROM Products p WITH (NOLOCK)
    WHERE ProductId = @ProductId;

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

    -- Perform calculations based on category
    IF (@TenantId = 1 OR @TenantId = 27)
    BEGIN
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
        IF NULLIF(@ProductWidth,0) IS NULL OR NULLIF(@ProductHeight,0) IS NULL OR NULLIF(@ProductDepth,0) IS NULL
        BEGIN
            SET @ProductWidth = 1;
            SET @ProductHeight = 1;
            SET @ProductDepth = 1;
        END
        SET @CostPerCubic = @CostPrice / (@ProductWidth * @ProductHeight * @ProductDepth);
        SET @TotalCubic = @Width * @Height * @Depth;
        SET @NewCostPrice = @TotalCubic * @CostPerCubic;
    END

    -- Calculate rounded price
    RETURN CAST(ROUND(
        CASE 
            WHEN @TenantAmountRoundMultiple IS NOT NULL AND @TenantAmountRoundMultiple > 0 THEN 
                @TenantAmountRoundMultiple * ROUND(@NewCostPrice / @TenantAmountRoundMultiple, 0)
            ELSE 
                @NewCostPrice
        END, 0
    ) AS NUMERIC(18, 0));
END;

GO

