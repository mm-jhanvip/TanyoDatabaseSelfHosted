/* ============================================================================
   Stored Procedure : usp_GetInwardDataV2
   Purpose          : Paged/filtered list of Inward entries — equivalent to
                       GetInwardDataV2() (C#/LINQ), joining Vendor, Customer,
                       Order and User (created/updated by).
   Notes:
     - Assumes InwardEntry has TenantId / IsDeleted columns (multi-tenant,
       soft-delete) even though not explicit in the LINQ — adjust/remove the
       @TenantId filter if not applicable.
     - Paging uses OFFSET/FETCH (SQL Server 2012+). @PageNumber is 1-based.
     - Sorting is fixed to Date DESC to match typical grid default; add a
       @SortColumn/@SortDirection pair if the DataTable needs dynamic sort.
   ============================================================================ 
   EXEC [GetInwardAllData]   
        @TenantId        = 2,
        @Name            = NULL,
        @OrderNo         = NULL,
        @InwardNumber    = NULL,
        @InwardFromDate  = NULL,
        @InwardToDate    = NULL,
        @ReceivedBy      = NULL,
        @PageNumber      = 1,
        @PageSize        = 1000,
        @SortBy = 'Date',
        @SortOrder = 'desc'

   */

CREATE PROCEDURE [dbo].[GetInwardAllData]
(
    @TenantId        INT,
    @Name            NVARCHAR(200) = NULL,
    @OrderNo         NVARCHAR(100) = NULL,
    @InwardNumber    NVARCHAR(100) = NULL,
    @InwardFromDate  DATE          = NULL,
    @InwardToDate    DATE          = NULL,
    @ReceivedBy      NVARCHAR(200) = NULL,
    @PageNumber      INT           = 1,
    @PageSize        INT           = 10,
	@SortBy VARCHAR(50) = 'Date',
	@SortOrder VARCHAR(50) = 'ASC'
)
WITH ENCRYPTION
AS
BEGIN
BEGIN TRY
    SET NOCOUNT ON;

    ;WITH InwardCte AS
    (
        SELECT
            x.InwardId,
            x.VendorId,
            x.CreatedDate                              AS [Date],
            x.InwardEntryNumber,
            ReceivedBy = CASE
                            WHEN userU.UserId IS NOT NULL
                                THEN userU.FirstName + N' ' + userU.LastName
                            ELSE userC.FirstName + N' ' + userC.LastName
                         END,
            x.CustomerId,
            [Name] = COALESCE(
                        NULLIF(LTRIM(RTRIM(cust.FirstName + N' ' + ISNULL(cust.LastName, N''))), N''),
                        NULLIF(LTRIM(RTRIM(vend.VendorName)), N''),
                        N'N/A'
                     ),
            x.OrderId,
            OrderNo = COALESCE(ord.OrderNo, x.PoNumber, st.StockTransferNo, 'N/A'),
			x.UpdatedDate AS [UpdatedDate]
        FROM dbo.InwardEntry x
        LEFT JOIN dbo.Vendors   vend ON vend.VendorId   = x.VendorId
        LEFT JOIN dbo.Customers cust ON cust.CustomerId = x.CustomerId
        LEFT JOIN dbo.[Orders]  ord  ON ord.OrderId     = x.OrderId
        LEFT JOIN dbo.[StockTransfer] st ON st.StockTransferId = x.StockTransferId
        INNER JOIN dbo.[AspNetUsers]  userC ON userC.UserId    = x.CreatedBy
        LEFT JOIN dbo.[AspNetUsers]   userU ON userU.UserId    = x.UpdatedBy
        WHERE x.TenantId = @TenantId
          AND x.IsDeleted = 0
    )
    SELECT *
    INTO #Filtered
    FROM InwardCte
    WHERE (@Name IS NULL OR @Name = N'' OR [Name] LIKE N'%' + @Name + N'%')
      AND (@InwardNumber IS NULL OR @InwardNumber = N'' OR InwardEntryNumber LIKE N'%' + @InwardNumber + N'%')
      AND (@InwardFromDate IS NULL OR CAST([Date] AS DATE) >= @InwardFromDate)
      AND (@InwardToDate   IS NULL OR CAST([Date] AS DATE) <= @InwardToDate)
      AND (@ReceivedBy IS NULL OR @ReceivedBy = N'' OR ReceivedBy LIKE N'%' + @ReceivedBy + N'%')
      AND (@OrderNo IS NULL OR @OrderNo = N'' OR OrderNo LIKE N'%' + @OrderNo + N'%')


    DECLARE @TotalCount INT = (SELECT COUNT(*) FROM #Filtered);

    SELECT
        InwardId, VendorId,CAST([Date] AS DATE) [Date], InwardEntryNumber, ReceivedBy,
        CustomerId, [Name], OrderId, OrderNo , @TotalCount AS TotalCount
    FROM #Filtered
		ORDER BY CASE WHEN @SortBy = 'Date' AND @SortOrder = 'ASC' THEN ISNULL([UpdatedDate], [Date]) END ASC
			,CASE WHEN @SortBy = 'Date' AND @SortOrder = 'DESC' THEN ISNULL([UpdatedDate], [Date]) END DESC
			,CASE WHEN @SortBy = 'InwardEntryNumber' AND @SortOrder = 'ASC' THEN InwardEntryNumber END
			,CASE WHEN @SortBy = 'InwardEntryNumber' AND @SortOrder = 'DESC' THEN InwardEntryNumber END DESC
			,CASE WHEN @SortBy = 'ReceivedBy' AND @SortOrder = 'ASC' THEN ReceivedBy END
			,CASE WHEN @SortBy = 'ReceivedBy' AND @SortOrder = 'DESC' THEN ReceivedBy END DESC
			,CASE WHEN @SortBy = 'Name' AND @SortOrder = 'ASC' THEN [Name] END
			,CASE WHEN @SortBy = 'Name' AND @SortOrder = 'DESC' THEN [Name] END DESC
			,CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'ASC' THEN OrderNo END
			,CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'DESC' THEN OrderNo END DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    DROP TABLE #Filtered;
END TRY
BEGIN CATCH
	DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);
	SET @ObjectName = OBJECT_NAME(@@PROCID);
	SET @ErrorMsg = ERROR_MESSAGE();

	EXEC dbo.SaveDBErrorLog
		@ObjectName = @ObjectName
		,@ErrorMsg = @ErrorMsg;

	THROW;
END CATCH
END

GO

