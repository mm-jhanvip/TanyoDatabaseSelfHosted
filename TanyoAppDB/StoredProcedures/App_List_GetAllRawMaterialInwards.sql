-- =============================================
-- Author:  MagnusMinds
-- Create date: 30-Oct-2025
-- Description: Get all Raw Material Inwards from dashboard
-- =============================================
/*
    --Admin
    EXEC App_List_GetAllRawMaterialInwards
        @TenantId = 2
*/ 
CREATE   PROCEDURE [dbo].[App_List_GetAllRawMaterialInwards]
(
    @TenantId INT
    ,@VendorName VARCHAR(200) = NULL
    ,@PoNumber VARCHAR(100) = NULL
    ,@InwardNumber VARCHAR(100) = NULL
    ,@InwardFromDate DATE = NULL
    ,@InwardToDate DATE = NULL
    ,@ReceivedBy VARCHAR(200) = NULL
    ,@PageNumber INT = 1
    ,@PageSize INT = 25
    ,@SortColumn VARCHAR(50) = 'Date'
    ,@SortDirection VARCHAR(4) = 'DESC'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    ;WITH InwardCTE AS (
        SELECT
            i.InwardId
            ,i.VendorId
            ,i.CreatedDate AS [Date]
            ,i.InwardEntryNumber
            ,i.PoNumber
            ,v.VendorName
            ,ISNULL(upd.FirstName + ' ' + upd.LastName, crt.FirstName + ' ' + crt.LastName) AS ReceivedBy
            ,COUNT(*) OVER() AS TotalCount
            ,ROW_NUMBER() OVER (
                ORDER BY
                    CASE WHEN @SortColumn = 'VendorName' AND @SortDirection = 'ASC' THEN v.VendorName END ASC,
                    CASE WHEN @SortColumn = 'VendorName' AND @SortDirection = 'DESC' THEN v.VendorName END DESC,
                    CASE WHEN @SortColumn = 'Date' AND @SortDirection = 'ASC' THEN i.CreatedDate END ASC,
                    CASE WHEN @SortColumn = 'Date' AND @SortDirection = 'DESC' THEN i.CreatedDate END DESC,
                    CASE WHEN @SortColumn = 'PoNumber' AND @SortDirection = 'ASC' THEN i.PoNumber END ASC,
                    CASE WHEN @SortColumn = 'PoNumber' AND @SortDirection = 'DESC' THEN i.PoNumber END DESC,
                    CASE WHEN @SortColumn = 'InwardEntryNumber' AND @SortDirection = 'ASC' THEN i.InwardEntryNumber END ASC,
                    CASE WHEN @SortColumn = 'InwardEntryNumber' AND @SortDirection = 'DESC' THEN i.InwardEntryNumber END DESC,
                    CASE WHEN @SortColumn = 'ReceivedBy' AND @SortDirection = 'ASC' THEN ISNULL(upd.FirstName + ' ' + upd.LastName, crt.FirstName + ' ' + crt.LastName) END ASC,
                    CASE WHEN @SortColumn = 'ReceivedBy' AND @SortDirection = 'DESC' THEN ISNULL(upd.FirstName + ' ' + upd.LastName, crt.FirstName + ' ' + crt.LastName) END DESC,
                    i.CreatedDate DESC -- fallback
            ) AS RowNum
        FROM RawMaterialInwardEntry i WITH (NOLOCK)
        LEFT JOIN Vendors v WITH (NOLOCK) ON i.VendorId = v.VendorId AND v.TenantId = @TenantId
        LEFT JOIN AspNetUsers crt WITH (NOLOCK) ON i.CreatedBy = crt.UserId
        LEFT JOIN AspNetUsers upd WITH (NOLOCK) ON i.UpdatedBy = upd.UserId
        WHERE i.TenantId = @TenantId
		AND i.IsDeleted = 0
        AND (@VendorName IS NULL OR v.VendorName LIKE '%' + @VendorName + '%')
        AND (@PoNumber IS NULL OR i.PoNumber LIKE '%' + @PoNumber + '%')
        AND (@InwardNumber IS NULL OR i.InwardEntryNumber LIKE '%' + @InwardNumber + '%')
        AND (@InwardFromDate IS NULL OR CAST(i.CreatedDate AS DATE) >= @InwardFromDate)
        AND (@InwardToDate IS NULL OR CAST(i.CreatedDate AS DATE) <= @InwardToDate)
        AND (@ReceivedBy IS NULL OR 
            ISNULL(upd.FirstName + ' ' + upd.LastName, crt.FirstName + ' ' + crt.LastName) LIKE '%' + @ReceivedBy + '%')
    )
    SELECT *
    FROM InwardCTE
    WHERE RowNum BETWEEN (@PageNumber - 1) * @PageSize + 1 AND @PageNumber * @PageSize;
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

