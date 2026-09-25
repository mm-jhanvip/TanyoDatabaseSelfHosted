/*
    EXEC GetWarehousewiseInward
     @TenantId = 154
    ,@RoleId = '0FC94370-F8D9-4AAD-8314-98140AEDE101'
    ,@CategoryId = NULL
    ,@SubCategoryId = NULL
    ,@SubGroupId = NULL
    ,@MaterialId = NULL
    ,@ColorId = NULL
    ,@BrandId = NULL

*/
CREATE PROCEDURE [dbo].[GetWarehousewiseInward]
(
    @TenantId INT
    ,@RoleId VARCHAR(100)
    ,@CategoryId INT = NULL
    ,@SubCategoryId INT = NULL
    ,@SubGroupId INT = NULL
    ,@MaterialId INT = NULL
    ,@ColorId INT = NULL
    ,@BrandId INT = NULL
)
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
    DECLARE @cols NVARCHAR(MAX)
        ,@Alias_cols NVARCHAR(MAX);

    DECLARE @query NVARCHAR(MAX);

    DECLARE @ProductMaterial BIGINT
        ,@ProductColour BIGINT
        ,@ProductBrand BIGINT
        ,@ProductCustomLabel BIGINT

    DECLARE @ProductCategory BIGINT
        ,@ProductSubCategory BIGINT
        ,@ProductSubGroup BIGINT

    SELECT @cols = STRING_AGG(QUOTENAME(Name), ',')
        ,@Alias_cols = STRING_AGG('ISNULL('+QUOTENAME(Name)+',0) AS '+ QUOTENAME(Name), ',')
    FROM Warehouse
    WHERE IsDeleted = 0
        AND TenantId = @TenantId;

    ;With CteLookups AS
    (
        SELECT LookupName
            ,LookupId
        FROM Lookups WITH (NOLOCK)
        WHERE TenantId = @TenantId
        AND LookupName IN ('ProductMaterial'
            ,'ProductColour'
            ,'ProductBrand'
            ,'ProductCustomLabel'
            )
    )
    SELECT  @ProductMaterial = (SELECT TOP (1) LookupId FROM CteLookups WHERE LookupName = 'ProductMaterial')
            ,@ProductColour = (SELECT TOP (1) LookupId FROM CteLookups WHERE LookupName = 'ProductColour')
            ,@ProductBrand = (SELECT TOP (1) LookupId FROM CteLookups WHERE LookupName = 'ProductBrand')
            ,@ProductCustomLabel = (SELECT TOP (1) LookupId FROM CteLookups WHERE LookupName = 'ProductCustomLabel')
    
        ;With CteLookupvalues AS
    (
        SELECT LookupValueName
        ,LookupValueId
        FROM LookupValues WITH (NOLOCK)
        WHERE LookupId = @ProductCustomLabel
            AND LookupValueName IN ('Category'
                ,'Sub Category'
                ,'Sub Group')
    )
    SELECT  @ProductCategory = (SELECT TOP (1) LookupValueId FROM CteLookupvalues WHERE LookupValueName = 'Category')
            ,@ProductSubCategory = (SELECT TOP (1) LookupValueId FROM CteLookupvalues WHERE LookupValueName = 'Sub Category')
            ,@ProductSubGroup = (SELECT TOP (1) LookupValueId FROM CteLookupvalues WHERE LookupValueName = 'Sub Group')

    SET @query = N'
    SELECT 
        ModelNo,
        ProductTitle,
        Category,
        SubCategory,
        SubGroup,
        Width,
        Height,
        Depth,
        Material,
        Color,
        Brand,
        HSNNo,
        PurchasePrice,
        MRP,
        Discount,
        RetailOfferPrice,
        WholesalerOfferPrice,
        ProductId,
        ' + @Alias_cols + '
    FROM (
        SELECT 
            p.ModelNo,
            p.ProductTitle,
            pcfc.CustomValue AS Category,
            pcfsc.CustomValue AS SubCategory,
            pcfsg.CustomValue AS SubGroup,
            p.Width,
            p.Height,
            p.Depth,
            lvm.LookupValueName AS Material,
            lvc.LookupValueName AS Color,
            lvb.LookupValueName AS Brand,
            p.HSNNo,
            p.CostPrice AS PurchasePrice,
            p.RetailerPrice AS MRP,
            co.OfferPercentage AS Discount,
            p.RetailOfferPrice,
            p.WholesalerOfferPrice,
            p.ProductId,
            ISNULL(w.Name,''Others'') AS WarehouseName,
            id.Quantity
        FROM Products p
        INNER JOIN Categories c ON c.CategoryId = p.CategoryId
        INNER JOIN InwardDetailsEntry id ON id.ProductId = p.ProductId AND id.IsDeleted = 0
        LEFT JOIN Warehouse w ON w.Id = id.WarehouseId AND w.IsDeleted = 0
        LEFT JOIN ProductOffers co ON co.ProductId = p.ProductId
        LEFT JOIN ProductCustomFields pcfc ON pcfc.ProductId = p.ProductId
            AND pcfc.LookupValueId = '+cast(@ProductCategory as varchar(10))+'
        LEFT JOIN ProductCustomFields pcfsc ON pcfsc.ProductId = p.ProductId
            AND pcfsc.LookupValueId = '+cast(@ProductSubCategory as varchar(10))+'
        LEFT JOIN ProductCustomFields pcfsg ON pcfsg.ProductId = p.ProductId
            AND pcfsg.LookupValueId = '+cast(@ProductSubGroup as varchar(10))+'
        LEFT JOIN LookupValues lvm ON lvm.LookupValueId = p.ProductMaterialId
            AND lvm.LookupId = '+cast(@ProductMaterial as varchar(10))+'
        LEFT JOIN LookupValues lvc ON lvc.LookupValueId = p.ProductColourId
            AND lvc.LookupId = '+cast(@ProductColour as varchar(10))+'
        LEFT JOIN LookupValues lvb ON lvb.LookupValueId = p.ProductBrandId
            AND lvb.LookupId = '+cast(@ProductBrand as varchar(10))+'
        WHERE p.Status <> 3
            AND p.TenantId = '+CAST(@TenantId AS VARCHAR(10))+'
            '+CASE WHEN @CategoryId IS NOT NULL THEN 'AND pcfc.Id = '+CAST(@CategoryId AS VARCHAR(10)) ELSE '' END+'
            '+CASE WHEN @SubCategoryId IS NOT NULL THEN 'AND pcfsc.Id = '+CAST(@SubCategoryId AS VARCHAR(10)) ELSE '' END+'
            '+CASE WHEN @SubGroupId IS NOT NULL THEN 'AND pcfsg.Id = '+CAST(@SubGroupId AS VARCHAR(10)) ELSE '' END+'
            '+CASE WHEN @MaterialId IS NOT NULL THEN 'AND lvm.LookupValueId = '+CAST(@MaterialId AS VARCHAR(10)) ELSE '' END+'
            '+CASE WHEN @ColorId IS NOT NULL THEN 'AND lvc.LookupValueId = '+CAST(@ColorId AS VARCHAR(10)) ELSE '' END+'
            '+CASE WHEN @BrandId IS NOT NULL THEN 'AND lvb.LookupValueId = '+CAST(@BrandId AS VARCHAR(10)) ELSE '' END+'
    ) AS SourceTable
    PIVOT (
        SUM(Quantity)
        FOR WarehouseName IN (' + @cols + ')
    ) AS PivotTable;
    '

    EXEC sp_executesql @query;
    END TRY
    BEGIN CATCH
        DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg
    END CATCH
END

GO

