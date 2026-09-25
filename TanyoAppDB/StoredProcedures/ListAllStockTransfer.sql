/*

 EXEC [ListAllStockTransfer]  
        @TenantId = 2,
        @UserId  = NULL,
        @StockTransferNo = NULL,
        @FromWarehouseId  = NULL,
        @ToWarehouseId   = NULL,
        @StockTransferStatus = NULL,
        @TransferFromDate = NULL,
        @TransferToDate = NULL,
		@SortBy = 'CreatedDate',
		@SortOrder = 'desc'
		
*/
CREATE   PROCEDURE [dbo].[ListAllStockTransfer] (
	@TenantId INT
	,@UserId INT = NULL
	,@StockTransferNo VARCHAR(20) = NULL
	,@FromWarehouseId INT = NULL
	,@ToWarehouseId INT = NULL
	,@StockTransferStatus INT = NULL
	,@TransferFromDate DATE = NULL
	,@TransferToDate DATE = NULL
	,@PageNumber INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'CreatedDate'
	,@SortOrder VARCHAR(4) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--SET @TransferFromDate = CAST(@TransferFromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30';
		--SET @TransferToDate = CAST(@TransferToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30';

		SELECT ST.StockTransferID
            ,ST.StockTransferNo
            ,ST.StockTransferStatus
            ,ST.TransferDate AS StockTransferDate
            ,W.Name AS FromWarehouse
            ,TW.Name AS ToWarehouse
			,SUM(SD.TransferQuantity) AS TransferQuantity
            ,COUNT(SD.StockTransferDetailId) AS TotalItems
            ,ST.CreatedBy
            ,LTRIM(RTRIM(ISNULL(AN.FirstName, '') + ' ' + ISNULL(AN.LastName, ''))) AS CreatedByUserName
            ,ST.ReceivedBy
            ,LTRIM(RTRIM(ISNULL(RB.FirstName, '') + ' ' + ISNULL(RB.LastName, ''))) AS ReceivedByUserName
			,COUNT(*) OVER () AS TotalCount
		FROM StockTransfer AS ST WITH (NOLOCK)
		INNER JOIN StockTransferDetail AS SD WITH(NOLOCK) ON ST.StockTransferId = SD.StockTransferId AND SD.IsDeleted = 0
		INNER JOIN Warehouse AS W WITH (NOLOCK) ON ST.FromWarehouseId = W.ID
		INNER JOIN Warehouse AS TW WITH (NOLOCK) ON ST.ToWarehouseId = TW.ID
		INNER JOIN AspNetUsers AS AN WITH (NOLOCK) ON ST.CreatedBy = AN.UserId
		LEFT JOIN AspNetUsers AS RB WITH (NOLOCK) ON ST.ReceivedBy = RB.UserId
		WHERE ST.TenantId = @TenantId
			AND ST.IsDeleted = 0
			AND (
				@StockTransferNo IS NULL
				OR ST.StockTransferNo LIKE '%' + @StockTransferNo + '%'
				)
			AND (
				@FromWarehouseId IS NULL
				OR ST.FromWarehouseId = @FromWarehouseId
				)
			AND (
				@ToWarehouseId IS NULL
				OR ST.ToWarehouseId = @ToWarehouseId
				)			
			--AND (
			--	@UserId IS NULL
			--	OR ST.CreatedBy = @UserId
			--	)
			AND (
				@StockTransferStatus IS NULL
				OR ST.StockTransferStatus = @StockTransferStatus
				)
			AND (
				@TransferFromDate IS NULL
				OR ST.TransferDate >= @TransferFromDate
				)
			AND (
				@TransferToDate IS NULL
				OR ST.TransferDate <= @TransferToDate
				)
		GROUP BY ST.StockTransferID
            ,ST.StockTransferNo
            ,ST.CreatedBy
            ,ST.ReceivedBy
            ,ST.StockTransferStatus
			,ST.TransferDate
            ,ST.CreatedDate
			,ST.UpdatedDate
            ,W.Name
            ,TW.Name
            ,AN.FirstName
            ,AN.LastName
            ,RB.FirstName
            ,RB.LastName
		ORDER BY 
			CASE 
				WHEN @SortBy = 'StockTransferNo'
					AND @SortOrder = 'ASC'
					THEN ST.StockTransferNo
				END ASC
			,CASE 
				WHEN @SortBy = 'StockTransferNo'
					AND @SortOrder = 'DESC'
					THEN ST.StockTransferNo
				END DESC
			,CASE 
				WHEN @SortBy = 'FromWarehouse'
					AND @SortOrder = 'ASC'
					THEN W.Name
				END ASC
			,CASE 
				WHEN @SortBy = 'FromWarehouse'
					AND @SortOrder = 'DESC'
					THEN W.Name
				END DESC
			,CASE 
				WHEN @SortBy = 'ToWarehouse'
					AND @SortOrder = 'ASC'
					THEN TW.Name
				END ASC
			,CASE 
				WHEN @SortBy = 'ToWarehouse'
					AND @SortOrder = 'DESC'
					THEN TW.Name
				END DESC
			,CASE 
				WHEN @SortBy = 'StockTransferDate'
					AND @SortOrder = 'ASC'
					THEN ST.TransferDate
				END ASC
			,CASE 
				WHEN @SortBy = 'StockTransferDate'
					AND @SortOrder = 'DESC'
					THEN ST.TransferDate
				END DESC
			,CASE 
				WHEN @SortBy = 'StockTransferStatus'
					AND @SortOrder = 'ASC'
					THEN ST.StockTransferStatus
				END ASC
			,CASE 
				WHEN @SortBy = 'StockTransferStatus'
					AND @SortOrder = 'DESC'
					THEN ST.StockTransferStatus
				END DESC
			,CASE 
				WHEN @SortBy = 'TransferQuantity'
					AND @SortOrder = 'ASC'
					THEN SUM(SD.TransferQuantity)
				END ASC
			,CASE 
				WHEN @SortBy = 'TransferQuantity'
					AND @SortOrder = 'DESC'
					THEN SUM(SD.TransferQuantity)
				END DESC
			,CASE 
				WHEN @SortBy = 'TotalItems'
					AND @SortOrder = 'ASC'
					THEN COUNT(SD.StockTransferDetailId)
				END ASC
			,CASE 
				WHEN @SortBy = 'TotalItems'
					AND @SortOrder = 'DESC'
					THEN COUNT(SD.StockTransferDetailId)
				END DESC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'ASC'
					THEN ISNULL(ST.UpdatedDate, ST.CreatedDate)
				END ASC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'DESC'
					THEN ISNULL(ST.UpdatedDate, ST.CreatedDate)
				END DESC
			,ISNULL(ST.UpdatedDate, ST.CreatedDate) DESC
		OFFSET(@PageNumber - 1) * @PageSize ROWS
		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
			
		SELECT ERROR_NUMBER() AS ErrorNumber
			,ERROR_MESSAGE() AS ErrorMessage
			,ERROR_LINE() AS ErrorLine
			,ERROR_PROCEDURE() AS ErrorProcedure;

		DECLARE @ObjectName VARCHAR(500)
				,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg
	END CATCH
END

GO

