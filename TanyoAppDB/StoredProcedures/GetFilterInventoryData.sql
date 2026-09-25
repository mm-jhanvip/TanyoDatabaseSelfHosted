/*
    EXEC [dbo].[GetFilterInventoryData]
        @TenantId = 1207,
        @CategoryTypeId = 2,
        @CategoryId = NULL,
        @ProductTitle = NULL,
        @ModelNo = NULL,
        @QuantityDate = NULL,
        @Quantity = NULL,
        @StockFilterOp = NULL,
        @SortBy = 'ProductQuantityId',
        @SortOrder = 'DESC',
        @PageIndex = 1,
        @PageSize = 1000
*/
CREATE PROCEDURE [dbo].[GetFilterInventoryData]
(
    @TenantId       INT,
    @CategoryTypeId BIGINT,
    @CategoryId     BIGINT = NULL,
    @ProductTitle   VARCHAR(150)= NULL,
    @ModelNo        VARCHAR(100) = NULL,
    @QuantityDate   DATETIMEOFFSET = NULL,
    @Quantity       DECIMAL(18,2) = NULL,
    @StockFilterOp  VARCHAR(5) = NULL,
    @SortBy         VARCHAR(50) = 'ProductQuantityId',
    @SortOrder      VARCHAR(10) = 'DESC',
    @PageIndex      INT = 1,
    @PageSize       INT = 25
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

         SELECT 
            pq.ProductQuantityId,
            pq.ProductId,
            p.ProductTitle,
            c.CategoryId,
            c.CategoryName,
            p.ModelNo,
            pq.QuantityDate,
            pq.Quantity,
            pq.MinimumLimit,
            pq.LastModifiedBy,
            u.FirstName + ' ' + u.LastName AS LastModifiedByName,
            pq.LastModifiedDate,
            pq.LastModifiedUTCDate,
            CASE WHEN @CategoryTypeId = 2 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsFabric,
            ISNULL(coverImage.ImagePath, '') AS CoverImage,
            COUNT(1) OVER () AS TotalCount
        FROM dbo.ProductQuantities pq WITH (NOLOCK)
        INNER JOIN dbo.Products p WITH (NOLOCK) 
            ON p.ProductId = pq.ProductId
        INNER JOIN dbo.Categories c WITH (NOLOCK) 
            ON c.CategoryId = p.CategoryId
        LEFT JOIN dbo.AspNetUsers u WITH (NOLOCK) 
            ON CONVERT(BIGINT, u.UserId) = pq.LastModifiedBy 
           AND u.IsDeleted = 0
           AND EXISTS (
               SELECT 1 FROM dbo.UserTenantMapping utm WITH (NOLOCK)
               WHERE utm.UserId = u.UserId AND utm.TenantId = @TenantId AND utm.IsDeleted = 0
           )
        OUTER APPLY (
            SELECT TOP (1) pi.ImagePath
            FROM dbo.ProductImages pi WITH (NOLOCK)
            WHERE pi.ProductId = pq.ProductId AND pi.IsCover = 1
            ORDER BY pi.CreatedDate ASC, pi.ProductImageID ASC
        ) AS coverImage

        WHERE p.TenantId = @TenantId
          AND c.TenantId = @TenantId
          AND c.CategoryTypeId = @CategoryTypeId
          AND c.IsDeleted = 0
          AND p.Status <> 2
          AND (@CategoryId IS NULL OR c.CategoryId = @CategoryId)
          AND (@ProductTitle IS NULL OR @ProductTitle = '' OR p.ProductTitle LIKE '%' + @ProductTitle + '%')
          AND (@ModelNo IS NULL OR @ModelNo = '' OR p.ModelNo LIKE '%' + @ModelNo + '%')
          AND (@QuantityDate IS NULL OR CONVERT(DATE, pq.QuantityDate) = CONVERT(DATE, @QuantityDate))
          AND (
              @Quantity IS NULL OR @StockFilterOp IS NULL
              OR (@StockFilterOp = '='  AND pq.Quantity = @Quantity)
              OR (@StockFilterOp = '>=' AND pq.Quantity >= @Quantity)
              OR (@StockFilterOp = '<=' AND pq.Quantity <= @Quantity)
          )
            ORDER BY
                CASE WHEN @SortBy = 'PRODUCTQUANTITYID' AND @SortOrder = 'ASC' THEN pq.ProductQuantityId END ASC,
                CASE WHEN @SortBy = 'PRODUCTQUANTITYID' AND @SortOrder = 'DESC' THEN pq.ProductQuantityId END DESC,
                CASE WHEN @SortBy = 'PRODUCTTITLE' AND @SortOrder = 'ASC' THEN p.ProductTitle END ASC,
                CASE WHEN @SortBy = 'PRODUCTTITLE' AND @SortOrder = 'DESC' THEN p.ProductTitle END DESC,
                CASE WHEN @SortBy = 'CATEGORYID' AND @SortOrder = 'ASC' THEN c.CategoryId END ASC,
                CASE WHEN @SortBy = 'CATEGORYID' AND @SortOrder = 'DESC' THEN c.CategoryId END DESC,
                CASE WHEN @SortBy = 'CATEGORYNAME' AND @SortOrder = 'ASC' THEN c.CategoryName END ASC,
                CASE WHEN @SortBy = 'CATEGORYNAME' AND @SortOrder = 'DESC' THEN c.CategoryName END DESC,
                CASE WHEN @SortBy = 'MODELNO' AND @SortOrder = 'ASC' THEN p.ModelNo END ASC,
                CASE WHEN @SortBy = 'MODELNO' AND @SortOrder = 'DESC' THEN p.ModelNo END DESC,
                CASE WHEN @SortBy = 'MINIMUMLIMIT' AND @SortOrder = 'ASC' THEN pq.MinimumLimit END ASC,
                CASE WHEN @SortBy = 'MINIMUMLIMIT' AND @SortOrder = 'DESC' THEN pq.MinimumLimit END DESC,
                CASE WHEN @SortBy = 'LASTMODIFIEDBYNAME' AND @SortOrder = 'ASC' THEN u.FirstName + ' ' + u.LastName END ASC,
                CASE WHEN @SortBy = 'LASTMODIFIEDBYNAME' AND @SortOrder = 'DESC' THEN u.FirstName + ' ' + u.LastName END DESC,
                CASE WHEN @SortBy = 'LASTMODIFIEDDATE' AND @SortOrder = 'ASC' THEN pq.LastModifiedDate END ASC,
                CASE WHEN @SortBy = 'LASTMODIFIEDDATE' AND @SortOrder = 'DESC' THEN pq.LastModifiedDate END DESC,
                CASE WHEN @SortBy = 'QUANTITYDATE' AND @SortOrder = 'ASC' THEN pq.QuantityDate END ASC,
                CASE WHEN @SortBy = 'QUANTITYDATE' AND @SortOrder = 'DESC' THEN pq.QuantityDate END DESC,
                CASE WHEN @SortBy = 'QUANTITY' AND @SortOrder = 'ASC' THEN pq.Quantity END ASC,
                CASE WHEN @SortBy = 'QUANTITY' AND @SortOrder = 'DESC' THEN pq.Quantity END DESC,
                pq.ProductQuantityId ASC
            OFFSET (@PageIndex - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ObjectName VARCHAR(500),
                @ErrorMsg NVARCHAR(4000);

        SET @ObjectName = OBJECT_NAME(@@PROCID);
        SET @ErrorMsg = ERROR_MESSAGE();

        EXEC [dbo].[SaveDBErrorLog]
            @ObjectName = @ObjectName,
            @ErrorMsg = @ErrorMsg;

    END CATCH
END

GO

