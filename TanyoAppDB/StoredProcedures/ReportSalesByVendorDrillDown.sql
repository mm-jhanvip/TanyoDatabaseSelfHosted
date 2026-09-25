/*
	EXEC [ReportSalesByVendorDrillDown]
		@TenantId = 2
		,@FromDate = NULL
		,@ToDate = NULL
		,@ProductCategory = NULL
		,@VendorId = 11
		,@PageIndex  = 1
		,@PageSize  = 50
		,@SortBy = 'InquiryDate'
		,@SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[ReportSalesByVendorDrillDown] (
	@TenantId INT
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@VendorId BIGINT = NULL
	,@ProductCategory INT = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@SortBy VARCHAR(50) = 'InquiryDate'
	,@SortOrder VARCHAR(4) = 'ASC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;;

	BEGIN TRY
		WITH CTE_Orders
		AS (
			SELECT DISTINCT ORD.OrderId
				,ORD.OrderNo AS InquiryNo
				,ORD.ApprovedDate AS InquiryDate
				,CONCAT (
					UC.FirstName
					,' '
					,UC.LastName
					) AS CustomerName
				,ORD.TotalAmount
				,CONCAT (
					US.FirstName
					,' '
					,US.LastName
					) AS SalesmanName
			FROM Orders ORD WITH (NOLOCK)
			INNER JOIN OrderSetItems OSI WITH (NOLOCK) ON ORD.OrderId = OSI.OrderId
			INNER JOIN Products PT WITH (NOLOCK) ON PT.ProductId = OSI.SubjectId
			INNER JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PVM.ProductId = PT.ProductId
			INNER JOIN Vendors V WITH (NOLOCK) ON V.VendorId = PVM.VendorId
			INNER JOIN Customers UC WITH (NOLOCK) ON UC.CustomerId = ORD.CustomerID
			INNER JOIN AspNetUsers US WITH (NOLOCK) ON US.UserId = ORD.SalesmanId
			WHERE ORD.TenantId = @TenantId
				AND ORD.Status IN (
					2
					,3
					,4
					,5
					)
				AND OSI.IsDeleted = 0
				AND (
					@FromDate IS NULL
					OR CONVERT(DATE, ORD.ApprovedDate) >= @FromDate
					)
				AND (
					@ToDate IS NULL
					OR CONVERT(DATE, ORD.ApprovedDate) <= @ToDate
					)
				AND (
					@VendorId IS NULL
					OR V.VendorId = @VendorId
					)
				AND (
					@ProductCategory IS NULL
					OR PT.CategoryId = @ProductCategory
					)
			)
		SELECT InquiryNo
			,InquiryDate
			,CustomerName
			,TotalAmount
			,SalesmanName
			,(
				SELECT COUNT(*)
				FROM CTE_Orders
				) AS TotalCount
		FROM CTE_Orders
		ORDER BY CASE 
				WHEN @SortBy = 'InquiryNo'
					AND @SortOrder = 'ASC'
					THEN InquiryNo
				END ASC
			,CASE 
				WHEN @SortBy = 'InquiryNo'
					AND @SortOrder = 'DESC'
					THEN InquiryNo
				END DESC
			,CASE 
				WHEN @SortBy = 'InquiryDate'
					AND @SortOrder = 'ASC'
					THEN InquiryDate
				END ASC
			,CASE 
				WHEN @SortBy = 'InquiryDate'
					AND @SortOrder = 'DESC'
					THEN InquiryDate
				END DESC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'ASC'
					THEN CustomerName
				END ASC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'DESC'
					THEN CustomerName
				END DESC
			,CASE 
				WHEN @SortBy = 'SalesmanName'
					AND @SortOrder = 'ASC'
					THEN SalesmanName
				END ASC
			,CASE 
				WHEN @SortBy = 'SalesmanName'
					AND @SortOrder = 'DESC'
					THEN SalesmanName
				END DESC
			,CASE 
				WHEN @SortBy = 'TotalAmount'
					AND @SortOrder = 'ASC'
					THEN TotalAmount
				END ASC
			,CASE 
				WHEN @SortBy = 'TotalAmount'
					AND @SortOrder = 'DESC'
					THEN TotalAmount
				END DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

