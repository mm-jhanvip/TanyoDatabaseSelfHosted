/*
	EXEC [dbo].[ListPORawMaterials]
		@TenantId = 125
*/
CREATE   PROC [dbo].[ListPORawMaterials]
(
	@TenantId BIGINT,
	@VendorId BIGINT = NULL,
	@PONumber VARCHAR(50) = NULL,
	@OrderFromDate DATE = NULL,
	@OrderToDate DATE = NULL,
	@Status INT = NULL,
	@PageIndex INT = 1,
	@PageSize INT = 10,
	@SortBy NVARCHAR(50) = 'OrderDate',
	@SortOrder NVARCHAR(4) = 'DESC'
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	SELECT p.PORawMaterialId
		,v.VendorName
		,p.PONumber
		,p.OrderDate AS OrderDate
		,p.Status
		,COUNT(i.PORawMaterialItemId) AS TotalPORawMaterialItems
		,ISNULL(uUpdated.FirstName + ' ' + uUpdated.LastName, uCreated.FirstName + ' ' + uCreated.LastName) AS LastModifiedBy
		,ISNULL(p.UpdatedDate, p.CreatedDate) AS LastModifiedDate
		,CASE 
			WHEN p.Status = 1 THEN 'Pending'
			WHEN p.Status = 2 THEN 'InProgress'
			WHEN p.Status = 3 THEN 'Completed'
			ELSE ''
		 END AS StatusName
		 ,MAX(p.TotalAmount) AS TotalAmount
		,COUNT(1) OVER() AS TotalCount
	FROM dbo.PORawMaterials p WITH (NOLOCK)
	INNER JOIN dbo.Vendors v WITH (NOLOCK) ON p.VendorId = v.VendorId
	LEFT JOIN dbo.PORawMaterialItems i WITH (NOLOCK) ON p.PORawMaterialId = i.PORawMaterialId
	LEFT JOIN dbo.AspNetUsers uCreated WITH (NOLOCK) ON p.CreatedBy = uCreated.UserId
	LEFT JOIN dbo.AspNetUsers uUpdated WITH (NOLOCK) ON p.UpdatedBy = uUpdated.UserId
	WHERE p.IsDeleted = 0
	AND p.TenantId = @TenantId
	AND (@VendorId IS NULL OR p.VendorId = @VendorId)
	AND (@PONumber IS NULL OR p.PONumber LIKE '%' + @PONumber + '%')
	AND (@OrderFromDate IS NULL OR p.OrderDate >= @OrderFromDate)
	AND (@OrderToDate IS NULL OR p.OrderDate <= @OrderToDate)
	AND (@Status IS NULL OR p.Status = @Status)
	GROUP BY 
		p.PORawMaterialId, v.VendorName, p.PONumber, p.OrderDate, p.Status,
		p.CreatedDate, p.UpdatedDate, uCreated.FirstName, uCreated.LastName,
		uUpdated.FirstName, uUpdated.LastName
	ORDER BY 
		CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'ASC' THEN v.VendorName END ASC
		,CASE WHEN @SortBy = 'VendorName' AND @SortOrder = 'DESC' THEN v.VendorName END DESC
		,CASE WHEN @SortBy = 'PONumber' AND @SortOrder = 'ASC' THEN p.PONumber END ASC
		,CASE WHEN @SortBy = 'PONumber' AND @SortOrder = 'DESC' THEN p.PONumber END DESC
		,CASE WHEN @SortBy = 'OrderDate' AND @SortOrder = 'ASC' THEN p.OrderDate END ASC
		,CASE WHEN @SortBy = 'OrderDate' AND @SortOrder = 'DESC' THEN p.OrderDate END DESC
		,CASE WHEN @SortBy = 'Status' AND @SortOrder = 'ASC' THEN p.Status END ASC
		,CASE WHEN @SortBy = 'Status' AND @SortOrder = 'DESC' THEN p.Status END DESC
		,CASE WHEN @SortBy = 'LastModifiedDate' AND @SortOrder = 'ASC' THEN ISNULL(p.UpdatedDate, p.CreatedDate) END ASC
		,CASE WHEN @SortBy = 'LastModifiedDate' AND @SortOrder = 'DESC' THEN ISNULL(p.UpdatedDate, p.CreatedDate) END DESC
		,CASE WHEN @SortBy = 'LastModifiedBy' AND @SortOrder = 'ASC' THEN ISNULL(uUpdated.FirstName + ' ' + uUpdated.LastName, uCreated.FirstName + ' ' + uCreated.LastName) END ASC
		,CASE WHEN @SortBy = 'LastModifiedBy' AND @SortOrder = 'DESC' THEN ISNULL(uUpdated.FirstName + ' ' + uUpdated.LastName, uCreated.FirstName + ' ' + uCreated.LastName) END DESC
		,CASE WHEN @SortBy = 'TotalAmount' AND @SortOrder = 'ASC' THEN MAX(p.TotalAmount) END ASC
		,CASE WHEN @SortBy = 'TotalAmount' AND @SortOrder = 'DESC' THEN MAX(p.TotalAmount) END DESC
	OFFSET (@PageIndex - 1) * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY
END

GO

