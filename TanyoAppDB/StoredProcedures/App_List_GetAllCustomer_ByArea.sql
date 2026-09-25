/*
EXEC [dbo].[App_List_GetAllCustomer_ByArea]
     @SearchArea  = 'Bodakdev',
     @TenantId    = 1206,
     @SortBy      = 'CustomerFullName',
     @SortOrder   = 'ASC',
     @PageNumber  = 1,
     @PageSize    = 100;
*/
CREATE PROCEDURE [dbo].[App_List_GetAllCustomer_ByArea] (
	@SearchArea NVARCHAR(200) = NULL
	,@TenantId INT
	,@SortBy NVARCHAR(100) = 'CustomerFullName'
	,@SortOrder NVARCHAR(4) = 'ASC'
	,@PageNumber INT = 1
	,@PageSize INT = 100
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT CA.CustomerAddressId
			,C.CustomerId
			,LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, ''))) AS CustomerFullName
			,CA.AddressType
			,CA.Street1
			,CA.Street2
			,CA.Landmark
			,CA.Area
			,CA.City
			,CA.STATE
			,CA.ZipCode
			,CA.IsDefault
			,CA.OtherAddressType
			,CA.CompanyName
			,CA.GSTNo
			,CA.Country
			,CA.FullAddress
			,COUNT(1) OVER () AS TotalCount
		FROM CustomerAddresses CA WITH (NOLOCK)
		INNER JOIN Customers C WITH (NOLOCK) ON C.CustomerId = CA.CustomerId
		WHERE CA.IsDeleted = 0
			AND C.IsDeleted = 0
			AND C.TenantId = @TenantId
			AND (
				@SearchArea IS NULL
				OR CA.Area LIKE '%' + @SearchArea + '%'
				OR CA.City LIKE '%' + @SearchArea + '%'
				OR CA.STATE LIKE '%' + @SearchArea + '%'
				OR CA.ZipCode LIKE '%' + @SearchArea + '%'
				OR CA.Country LIKE '%' + @SearchArea + '%'
				OR CA.FullAddress LIKE '%' + @SearchArea + '%'
				OR CA.Street1 LIKE '%' + @SearchArea + '%'
				OR CA.Street2 LIKE '%' + @SearchArea + '%'
				)
			AND NOT EXISTS (
				SELECT 1
				FROM CustomerAddresses CA2 WITH (NOLOCK)
				WHERE CA2.CustomerId = CA.CustomerId
					AND CA2.Area = CA.Area
					AND CA2.IsDeleted = 0
					AND CA2.CustomerAddressId > CA.CustomerAddressId
				)
		ORDER BY
			-- FullName
			CASE 
				WHEN @SortBy = 'CustomerFullName'
					AND @SortOrder = 'ASC'
					THEN LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, '')))
				END ASC
			,CASE 
				WHEN @SortBy = 'CustomerFullName'
					AND @SortOrder = 'DESC'
					THEN LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, '')))
				END DESC OFFSET(@PageNumber - 1) * @PageSize ROWS

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
END;

GO

