/*
EXEC [dbo].[GetPortalInwardList]
    @TenantId = 1206,
    @CategoryTypeId = 1, -- 1=Product, 2=Fabric
    @VendorId = -1,
    @InwardNo = NULL,
    @PoNo = NULL,
    @ProductId = -1,
    @InwardFromDate = NULL,
    @InwardToDate = NULL,
    @WarehouseId = -1,
    @PageIndex = 1,
    @PageSize = 100,
    @SortBy = N'UpdatedDate',
    @SortOrder = N'DESC'
*/
CREATE   PROCEDURE [dbo].[GetPortalInwardList]
(
    @TenantId INT,
    @CategoryTypeId BIGINT, -- 1=Product, 2=Fabric
    @VendorId BIGINT = -1,
    @InwardNo NVARCHAR(100) = NULL,
    @PoNo NVARCHAR(100) = NULL,
    @ProductId BIGINT = -1,
    @InwardFromDate DATE = NULL,
    @InwardToDate DATE = NULL,
    @WarehouseId BIGINT = -1,
    @PageIndex INT = 1,
    @PageSize INT = 10,
    @SortBy NVARCHAR(50) = N'UpdatedDate',
    @SortOrder NVARCHAR(10) = N'DESC'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @Offset INT = (@PageIndex - 1) * @PageSize;

        ------------------------------------------------------------------
        -- Headers that belong to CategoryType (include deleted products)
        ------------------------------------------------------------------
        ;WITH CategoryTypedProducts AS
        (
            SELECT p.ProductId
            FROM dbo.Products p WITH (NOLOCK)
            INNER JOIN dbo.Categories c WITH (NOLOCK) ON c.CategoryId = p.CategoryId
            WHERE c.CategoryTypeId = @CategoryTypeId
              AND p.TenantId = @TenantId
        ),
        MatchingInwards AS
        (
            SELECT DISTINCT
                x.InwardId
            FROM dbo.InwardEntry x WITH (NOLOCK)
            INNER JOIN dbo.InwardDetailsEntry d WITH (NOLOCK) ON d.InwardId = x.InwardId AND d.IsDeleted = 0
            INNER JOIN CategoryTypedProducts ctp ON ctp.ProductId = d.ProductId
            WHERE x.TenantId = @TenantId
              AND x.IsDeleted = 0
              AND (@VendorId IS NULL OR x.VendorId = @VendorId)
              AND (@InwardNo IS NULL OR @InwardNo = N'' OR x.InwardEntryNumber LIKE N'%' + @InwardNo + N'%')
              AND (@PoNo IS NULL OR @PoNo = N'' OR ISNULL(x.PoNumber, N'') LIKE N'%' + @PoNo + N'%')
              AND (@InwardFromDate IS NULL OR CAST(x.CreatedDate AS DATE) >= @InwardFromDate)
              AND (@InwardToDate IS NULL OR CAST(x.CreatedDate AS DATE) <= @InwardToDate)
              AND (@ProductId IS NULL OR d.ProductId = @ProductId)
              AND (@WarehouseId IS NULL OR d.WarehouseId = @WarehouseId)
        ),
        HeaderRows AS
        (
            SELECT
                x.InwardId,
                VendorId = CAST(ISNULL(v.VendorId, x.VendorId) AS BIGINT),
                VendorName = ISNULL(v.VendorName, N''),
                InwardNo = x.InwardEntryNumber,
                PONo = x.PoNumber,
                EnteredBy = ISNULL(usr.FirstName + N' ' + usr.LastName, N''),
                InwardDate = x.CreatedDate,
                UpdatedDate = ISNULL(x.UpdatedDate, x.CreatedDate),
                isInwardDetails = CAST(1 AS BIT)
            FROM dbo.InwardEntry x WITH (NOLOCK)
            INNER JOIN MatchingInwards m ON m.InwardId = x.InwardId
            LEFT JOIN dbo.Vendors v WITH (NOLOCK) ON v.VendorId = x.VendorId
            OUTER APPLY
            (
                SELECT TOP 1 u.FirstName, u.LastName
                FROM dbo.AspNetUsers u WITH (NOLOCK)
                WHERE u.UserId = COALESCE(x.UpdatedBy, x.CreatedBy)
            ) usr
        ),
        Counted AS
        (
            SELECT *, TotalCount = COUNT(1) OVER() FROM HeaderRows
        )
        SELECT
            p.InwardId,
            p.VendorId,
            p.VendorName,
            p.InwardNo,
            p.PONo,
            p.EnteredBy,
            p.InwardDate,
            p.UpdatedDate,
            p.isInwardDetails,
            p.TotalCount
        FROM Counted p
        ORDER BY
            CASE WHEN @SortBy = N'InwardNo' AND @SortOrder = N'ASC' THEN p.InwardNo END ASC,
            CASE WHEN @SortBy = N'InwardNo' AND @SortOrder = N'DESC' THEN p.InwardNo END DESC,
            CASE WHEN @SortBy = N'VendorName' AND @SortOrder = N'ASC' THEN p.VendorName END ASC,
            CASE WHEN @SortBy = N'VendorName' AND @SortOrder = N'DESC' THEN p.VendorName END DESC,
            CASE WHEN @SortBy = N'PONo' AND @SortOrder = N'ASC' THEN p.PONo END ASC,
            CASE WHEN @SortBy = N'PONo' AND @SortOrder = N'DESC' THEN p.PONo END DESC,
            CASE WHEN @SortBy = N'EnteredBy' AND @SortOrder = N'ASC' THEN p.EnteredBy END ASC,
            CASE WHEN @SortBy = N'EnteredBy' AND @SortOrder = N'DESC' THEN p.EnteredBy END DESC,
            CASE WHEN @SortBy = N'InwardDate' AND @SortOrder = N'ASC' THEN p.InwardDate END ASC,
            CASE WHEN @SortBy = N'InwardDate' AND @SortOrder = N'DESC' THEN p.InwardDate END DESC,
            CASE WHEN @SortBy = N'UpdatedDate' AND @SortOrder = N'ASC' THEN p.UpdatedDate END ASC,
            CASE WHEN (@SortBy = N'UpdatedDate' OR @SortBy IS NULL OR @SortBy = N'') AND @SortOrder = N'DESC' THEN p.UpdatedDate END DESC,
            CASE WHEN (@SortBy = N'UpdatedDate' OR @SortBy IS NULL OR @SortBy = N'') AND @SortOrder = N'ASC' THEN p.UpdatedDate END ASC,
            p.UpdatedDate DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

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

