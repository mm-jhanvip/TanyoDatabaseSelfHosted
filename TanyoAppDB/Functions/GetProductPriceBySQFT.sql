/*
    -- Wholesaler Price Permission is OFF.
    -- SQFT Products, it will return actual price.
    SELECT [dbo].[GetProductPriceBySQFT] ('17BE52F0-731D-4215-9CA3-021C068A9F6F', 2, 97677, 1) -- Cost Price
    SELECT [dbo].[GetProductPriceBySQFT] ('17BE52F0-731D-4215-9CA3-021C068A9F6F', 2, 97677, 2) -- Retailer Price
    SELECT [dbo].[GetProductPriceBySQFT] ('17BE52F0-731D-4215-9CA3-021C068A9F6F', 2, 97677, 3) -- Retailer Offer Price

    -- Wholesaler Price Permission is ON.
    -- SQFT Products, it will return actual price.
    SELECT [dbo].[GetProductPriceBySQFT] ('A5F9B751-0741-4787-856D-5F74017E93B5', 2, 97677, 1) -- Cost Price
    SELECT [dbo].[GetProductPriceBySQFT] ('A5F9B751-0741-4787-856D-5F74017E93B5', 2, 97677, 2) -- Wholesaler Price
    SELECT [dbo].[GetProductPriceBySQFT] ('A5F9B751-0741-4787-856D-5F74017E93B5', 2, 97677, 3) -- Wholesaler Offer Price
*/
CREATE   FUNCTION [dbo].[GetProductPriceBySQFT]
(
    @RoleId NVARCHAR(50)
    ,@TenantId INT
    ,@ProductId INT
    ,@PriceType INT
)
RETURNS DECIMAL(18, 2)
WITH ENCRYPTION
AS
BEGIN

    -- 1. Cost | 2. Retailer/Wholesaler | 3. Retailer Offer 
    -- 4. Wholesaler Price ONLY | 5. Retailer Price ONLY | 6. Retailer Offer Price ONLY

    DECLARE @HasWholesalerPrice BIT = 0;
    DECLARE @ProductPrice DECIMAL(18, 2);
    DECLARE @CostPrice DECIMAL(18, 2);
    DECLARE @RetailerPrice DECIMAL(18, 2);
    DECLARE @RetailerOfferPrice DECIMAL(18, 2);
    DECLARE @WholesalerPrice DECIMAL(18, 2);
    DECLARE @CategoryName NVARCHAR(255);
    DECLARE @IsProduct BIT = 0;

    IF (@RoleId IS NOT NULL AND @RoleId <> '')
    BEGIN
        SELECT @HasWholesalerPrice = CASE WHEN EXISTS (
            SELECT 1 
            FROM AspNetRoleClaims WITH (NOLOCK)
            WHERE RoleId = @RoleId
            AND ClaimValue = 'Permissions.App.Order.WholeselerPrice'
        ) THEN 1 ELSE 0 END;
    END

    -- Fetch product data
    SELECT @CostPrice = CAST((IIF(p.CostPrice = 0, p.RetailerPrice, p.CostPrice)) * pcm.CustomValue AS NUMERIC(18,2))
	    ,@RetailerPrice = CAST(p.RetailerPrice * pcm.CustomValue AS NUMERIC(18,2))
	    ,@RetailerOfferPrice = CAST(ISNULL(p.RetailOfferPrice, 0) * pcm.CustomValue AS NUMERIC(18,2))
	    ,@WholesalerPrice = CAST(p.WholesalerPrice * pcm.CustomValue AS NUMERIC(18,2))
        ,@CategoryName = (SELECT CategoryName FROM Categories WITH (NOLOCK) WHERE CategoryId = p.CategoryId)
    FROM ProductCustomFields pcm
    INNER JOIN Products p WITH (NOLOCK) ON p.ProductId = pcm.ProductId
	    AND p.Status <> 3
	    AND p.TenantId = @TenantId
    INNER JOIN Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
	    AND c.IsDeleted = 0
	    AND c.TenantId = @TenantId
	    AND c.IsSellByPerSQFT = 1
    INNER JOIN LookupValues lv WITH (NOLOCK) ON lv.LookupValueId = pcm.LookupValueId
    INNER JOIN Lookups l WITH (NOLOCK) ON l.LookupId = lv.LookupId
	    AND l.IsDeleted = 0
    WHERE l.TenantId = @TenantId
    AND lv.LookupValueName = 'SQFT in BOX'
    AND pcm.ProductId = @ProductId
    AND pcm.IsDeleted = 0

    -- Check if the category is a product category and sell by Per SQFT
    IF EXISTS (SELECT TOP 1 1
            FROM Categories c WITH (NOLOCK)
            WHERE c.CategoryName = @CategoryName
            AND c.TenantId = @TenantId
            AND c.CategoryTypeId = 1
            AND c.IsSellByPerSQFT = 1)
    BEGIN
        SET @IsProduct = 1
    END

    IF @PriceType = 1 -- Product Cost Price
    BEGIN
        SET @ProductPrice = @CostPrice
    END
    ELSE IF @PriceType = 2 -- Product Retailer/Wholesaler Price
    BEGIN
        IF @HasWholesalerPrice = 1 -- Check Wholesaler Price permission
        BEGIN
            SET @ProductPrice = @WholesalerPrice
        END
        ELSE
        BEGIN
            SET @ProductPrice = @RetailerPrice
        END
    END
    ELSE IF @PriceType = 3 -- Product Retailer Offer Price
    BEGIN
        IF @HasWholesalerPrice = 1 -- Check Wholesaler Price permission
        BEGIN
            SET @ProductPrice = 0.00 -- No Offer applicable in Wholesaler Price
        END
        ELSE
        BEGIN
            SET @ProductPrice = @RetailerOfferPrice
        END
    END
    ELSE IF @PriceType = 4 -- Product Wholesaler Price ONLY
    BEGIN
        SET @ProductPrice = @WholesalerPrice
    END
    ELSE IF @PriceType = 5 -- Product Retailer Price ONLY
    BEGIN
        SET @ProductPrice = @RetailerPrice
    END
    ELSE IF @PriceType = 6 -- Product Retailer Offer Price ONLY
    BEGIN
        SET @ProductPrice = @RetailerOfferPrice
    END

    -- If not a product category, return price
    IF @IsProduct = 0
    BEGIN
        RETURN ISNULL(@ProductPrice, 0)
    END

    -- Calculate rounded price
    RETURN CAST(ROUND(ISNULL(@ProductPrice, 0), 2) AS NUMERIC(18, 2));
END

GO

