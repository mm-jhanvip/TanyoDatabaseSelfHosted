/*
EXEC [dbo].[GetPortalInwardDetails]
    @InwardId = 62535,
    @CategoryTypeId = 1, -- 1=Product, 2=Fabric
    @WarehouseId = -1
*/
CREATE   PROCEDURE [dbo].[GetPortalInwardDetails]
(
    @InwardId BIGINT,
    @CategoryTypeId BIGINT,
    @WarehouseId BIGINT = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        SELECT
            inwardDetailsId = d.InwardDetailsId,
            productId = CAST(d.ProductId AS BIGINT),
            categoryId = c.CategoryId,
            productTitle = pr.ProductTitle,
            categoryName = c.CategoryName,
            modelNo = pr.ModelNo,
            quantity = d.Quantity,
            amount = d.Amount,
            remark = d.Remark,
            imagePath = ISNULL(d.ImagePath, N''),
            warehouseId = d.WarehouseId,
            warehouseName = ISNULL(w.Name, N'-')
        FROM dbo.InwardDetailsEntry d WITH (NOLOCK)
        INNER JOIN dbo.Products pr WITH (NOLOCK)
            ON pr.ProductId = d.ProductId
            AND pr.Status <> 3 -- ProductStatusEnum.Delete
        INNER JOIN dbo.Categories c WITH (NOLOCK)
            ON c.CategoryId = pr.CategoryId
            AND c.IsDeleted = 0
            AND c.CategoryTypeId = @CategoryTypeId
        LEFT JOIN dbo.Warehouse w WITH (NOLOCK)
            ON w.Id = d.WarehouseId
        WHERE d.InwardId = @InwardId
          AND d.IsDeleted = 0
          AND (@WarehouseId IS NULL OR d.WarehouseId = @WarehouseId)
        ORDER BY d.InwardDetailsId;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(MAX),
                @ObjectName VARCHAR(500);

        SELECT
            @ErrorMessage = ERROR_MESSAGE(),
            @ObjectName = OBJECT_NAME(@@PROCID);

        EXEC dbo.SaveDBErrorLog
            @ObjectName = @ObjectName,
            @ErrorMsg = @ErrorMessage;
    END CATCH
END

GO

