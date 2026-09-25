/*
EXEC SalesReturnDetailsByCustomer
    @TenantId = 125
    ,@CustomerId = 2
    ,@InwardNo = NULL
    ,@OrderNo = NULL
    ,@ProductTitle = NULL
    ,@ModelNo = NULL
    ,@PageIndex = 1
    ,@PageSize = 20
    ,@SortBy = 'CreatedDate'
    ,@SortOrder = 'DESC'
*/
CREATE PROCEDURE [dbo].[SalesReturnDetailsByCustomer] (
	@TenantId INT
	,@CustomerId BIGINT
	,@InwardNo VARCHAR(100) = NULL
	,@OrderNo VARCHAR(100) = NULL
	,@ProductTitle VARCHAR(200) = NULL
	,@ModelNo VARCHAR(200) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 20
	,@SortBy VARCHAR(50) = 'CreatedDate'
	,@SortOrder VARCHAR(4) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @Offset INT = (@PageIndex - 1) * @PageSize;

		SELECT IE.InwardId
			,IE.CreatedDate
			,ISNULL(ORD.OrderNo, '') AS OrderNo
			,ORD.OrderId AS OrderId
			,CAST(CASE 
					WHEN ISNULL(ORD.Status, 0) = 9
						THEN 1
					ELSE 0
					END AS BIT) AS IsOrderDeleted
			,IE.InwardEntryNumber AS InwardNo
			,ISNULL((
					SELECT IED.InwardDetailsId
						,PT.ProductId
						,PT.ProductTitle
						,PT.ModelNo
						,ISNULL(IED.WarehouseId, 0) AS WarehouseId
						,ISNULL(W.Name, '') AS WarehouseName
						,IED.Quantity AS ReturnQty
					FROM InwardDetailsEntry IED WITH (NOLOCK)
					INNER JOIN Products PT WITH (NOLOCK) ON IED.ProductId = PT.ProductId
					LEFT JOIN Warehouse W WITH (NOLOCK) ON W.Id = IED.WarehouseId
					WHERE IE.InwardId = IED.InwardId
						AND IED.IsDeleted = 0
					FOR JSON PATH
					), '[]') AS InwardDetailsEntry
			,COUNT(1) OVER () AS TotalCount
		FROM InwardEntry IE WITH (NOLOCK)
		LEFT JOIN Orders ORD WITH (NOLOCK) ON IE.OrderId = ORD.OrderId
		WHERE IE.IsDeleted = 0
			AND IE.InwardType = 3
			AND IE.CustomerId = @CustomerId
			AND IE.TenantId = @TenantId
			---------------------------------------------------
			-- Filters
			---------------------------------------------------
			AND (
				@InwardNo IS NULL
				OR IE.InwardEntryNumber LIKE '%' + @InwardNo + '%'
				)
			AND (
				@OrderNo IS NULL
				OR ORD.OrderNo LIKE '%' + @OrderNo + '%'
				)
			AND (
				@ProductTitle IS NULL
				OR EXISTS (
					SELECT 1
					FROM InwardDetailsEntry IED WITH (NOLOCK)
					INNER JOIN Products PT WITH (NOLOCK) ON IED.ProductId = PT.ProductId
					WHERE IED.InwardId = IE.InwardId
						AND IED.IsDeleted = 0
						AND PT.ProductTitle LIKE '%' + @ProductTitle + '%'
					)
				)
			AND (
				@ModelNo IS NULL
				OR EXISTS (
					SELECT 1
					FROM InwardDetailsEntry IED WITH (NOLOCK)
					INNER JOIN Products PT WITH (NOLOCK) ON IED.ProductId = PT.ProductId
					WHERE IED.InwardId = IE.InwardId
						AND IED.IsDeleted = 0
						AND PT.ModelNo LIKE '%' + @ModelNo + '%'
					)
				)
		ORDER BY CASE 
				WHEN @SortBy = 'InwardNo'
					AND @SortOrder = 'ASC'
					THEN IE.InwardEntryNumber
				END ASC
			,CASE 
				WHEN @SortBy = 'InwardNo'
					AND @SortOrder = 'DESC'
					THEN IE.InwardEntryNumber
				END DESC
			,CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'ASC'
					THEN ORD.OrderNo
				END ASC
			,CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'DESC'
					THEN ORD.OrderNo
				END DESC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'ASC'
					THEN IE.CreatedDate
				END ASC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'DESC'
					THEN IE.CreatedDate
				END DESC
			,
			-- Default Sorting
			IE.CreatedDate DESC OFFSET @Offset ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

