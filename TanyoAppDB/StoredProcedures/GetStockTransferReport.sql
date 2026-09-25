
/*
EXEC GetStockTransferReport
    @TenantId = 2
    ,@UserId = 4279
    ,@ProductTitle = NULL
    ,@ModelNo = NULL
    ,@FromWarehouseId = NULL
    ,@ToWarehouseId = NULL
    ,@TransferFromDate = NULL
    ,@TransferToDate = NULL
    ,@PageIndex = 1
    ,@PageSize = 20
    ,@SortBy = 'TransferDate'
    ,@SortOrder = 'DESC'
*/
CREATE   PROCEDURE [dbo].[GetStockTransferReport]
(
    @TenantId BIGINT
    ,@UserId BIGINT
    ,@ProductTitle VARCHAR(200) = NULL
    ,@ModelNo VARCHAR(100) = NULL
    ,@FromWarehouseId BIGINT = NULL
    ,@ToWarehouseId BIGINT = NULL
    ,@TransferFromDate DATE = NULL
    ,@TransferToDate DATE = NULL
    ,@PageIndex INT = 1
    ,@PageSize INT = 20
    ,@SortBy VARCHAR(50) = 'TransferDate'
    ,@SortOrder VARCHAR(4) = 'DESC'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    DECLARE @Offset INT = (@PageIndex - 1) * @PageSize;

    SELECT
        STL.StockTransferId
        ,FORMAT(STL.CreatedDate, 'dd/MM/yyyy hh:mm tt') AS TransferDate
        ,P.ProductId
        ,P.ProductTitle
        ,P.ModelNo
        ,P.CoverImage AS ProductImage
        ,FW.Id AS FromWarehouseId
        ,FW.Name AS FromWarehouseName
        ,TW.Id AS ToWarehouseId
        ,TW.Name AS ToWarehouseName
        ,CAST(STL.Quantity AS DECIMAL(18,2)) AS QuantityTransferred
        ,STL.CreatedBy
        ,CONCAT(ISNULL(U.FirstName,''), ' ', ISNULL(U.LastName,'') ) AS TransferredByUser
        ,COUNT(*) OVER() AS TotalCount
    FROM StockTransferLog STL WITH (NOLOCK)
    INNER JOIN Products P WITH (NOLOCK)
        ON STL.ProductId = P.ProductId
    LEFT JOIN Warehouse FW WITH (NOLOCK)
        ON STL.FromWarehouseId = FW.Id
    LEFT JOIN Warehouse TW WITH (NOLOCK)
        ON STL.ToWarehouseId = TW.Id
    LEFT JOIN AspNetUsers U WITH (NOLOCK)
        ON STL.CreatedBy = U.UserId
    WHERE
        STL.TenantId = @TenantId
        -- Product Title
        AND (
            @ProductTitle IS NULL
            OR P.ProductTitle LIKE '%' + @ProductTitle + '%'
        )
        -- Model No
        AND (
            @ModelNo IS NULL
            OR P.ModelNo LIKE '%' + @ModelNo + '%'
        )
        -- From Warehouse
        AND (
            @FromWarehouseId IS NULL
            OR STL.FromWarehouseId = @FromWarehouseId
        )
        -- To Warehouse
        AND (
            @ToWarehouseId IS NULL
            OR STL.ToWarehouseId = @ToWarehouseId
        )
        -- Transfer From Date
        AND (
            @TransferFromDate IS NULL
            OR CONVERT(DATE, STL.CreatedDate) >= @TransferFromDate
        )
        -- Transfer To Date
        AND (
            @TransferToDate IS NULL
            OR CONVERT(DATE, STL.CreatedDate) <= @TransferToDate
        )
        
    ORDER BY

        CASE WHEN @SortBy = 'TransferDate' AND @SortOrder = 'ASC' THEN STL.CreatedDate END ASC,
        CASE WHEN @SortBy = 'TransferDate' AND @SortOrder = 'DESC' THEN STL.CreatedDate END DESC,

        CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'ASC' THEN P.ProductTitle END ASC,
        CASE WHEN @SortBy = 'ProductTitle' AND @SortOrder = 'DESC' THEN P.ProductTitle END DESC,

        CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'ASC' THEN P.ModelNo END ASC,
        CASE WHEN @SortBy = 'ModelNo' AND @SortOrder = 'DESC' THEN P.ModelNo END DESC,

        CASE WHEN @SortBy = 'QuantityTransferred' AND @SortOrder = 'ASC' THEN STL.Quantity END ASC,
        CASE WHEN @SortBy = 'QuantityTransferred' AND @SortOrder = 'DESC' THEN STL.Quantity END DESC,

        CASE WHEN @SortBy = 'FromWarehouseName' AND @SortOrder = 'ASC' THEN FW.Name END ASC,
        CASE WHEN @SortBy = 'FromWarehouseName' AND @SortOrder = 'DESC' THEN FW.Name END DESC,

        CASE WHEN @SortBy = 'ToWarehouseName' AND @SortOrder = 'ASC' THEN TW.Name END ASC,
        CASE WHEN @SortBy = 'ToWarehouseName' AND @SortOrder = 'DESC' THEN TW.Name END DESC,

        CASE WHEN @SortBy = 'TransferredByUser' AND @SortOrder = 'ASC' THEN CONCAT(ISNULL(U.FirstName,''), ' ', ISNULL(U.LastName,'') ) END ASC,
        CASE WHEN @SortBy = 'TransferredByUser' AND @SortOrder = 'DESC' THEN CONCAT(ISNULL(U.FirstName,''), ' ', ISNULL(U.LastName,'') ) END DESC,

        -- Default Sorting
        STL.CreatedDate DESC

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
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

