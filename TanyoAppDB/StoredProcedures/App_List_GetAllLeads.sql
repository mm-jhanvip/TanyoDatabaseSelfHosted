/*  
EXEC App_List_GetAllLeads  
 @TenantId = 1207  
 ,@CurrentUserId = 13305  
 ,@RoleId = 'A636A96E-93E7-4264-8358-A6CCCBF44088'  
*/
CREATE PROCEDURE [dbo].[App_List_GetAllLeads] (
	@TenantId INT
	,@CurrentUserId BIGINT
	,@RoleId NVARCHAR(100)
	,@CustomerName VARCHAR(200) = NULL
	,@StatusId INT = NULL
	,@SalesmanId BIGINT = NULL
	,@PhoneNumber VARCHAR(50) = NULL
	,@InquiryFromDate DATE = NULL
	,@InquiryToDate DATE = NULL
	,@FollowUpFromDate DATE = NULL
	,@FollowUpToDate DATE = NULL
	,@PageNumber INT = 1
	,@PageSize INT = 25
	,@SortColumn VARCHAR(50) = 'UpdatedDate'
	,@SortDirection VARCHAR(4) = 'DESC'
	,@LeadSourceId BIGINT = NULL
	,@CustomerId BIGINT = NULL
	,@LeadNumber VARCHAR(15) = NULL
	,@PriorityId INT = NULL
	,@BuyingRangeValueId BIGINT = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IsAdmin BIT = 0
		,@HasSuperAccess BIT = 0;

	BEGIN TRY
		IF EXISTS (
				SELECT 1
				FROM AspNetRoles WITH (NOLOCK)
				WHERE Id = @RoleId
					AND [Name] = 'Administrator_' + CAST(@TenantId AS VARCHAR(5))
				)
			SET @IsAdmin = 1;

		IF EXISTS (
				SELECT 1
				FROM AspNetRoleClaims WITH (NOLOCK)
				WHERE RoleId = @RoleId
					AND ClaimValue = 'Permissions.App.Lead.SuperAccess'
				)
			SET @HasSuperAccess = 1;

		CREATE TABLE #UserLocations (LocationID INT);

		INSERT INTO #UserLocations (LocationID)
		SELECT LocationID
		FROM LocationUserMapping WITH (NOLOCK)
		WHERE UserId = @CurrentUserId;

		DECLARE @SelectQuery NVARCHAR(MAX)
			,@WhereQuery NVARCHAR(MAX) = ''
			,@OrderByQuery NVARCHAR(MAX) = ' ORDER BY '
			,@FinalQuery NVARCHAR(MAX)
			,@Params NVARCHAR(MAX);

		SET @SelectQuery = 
			N'  
 SELECT l.LeadId  
  ,l.Notes AS Inquiry  
  ,l.InquiryAbout  
  ,l.InquiryFor  
  ,l.RefferedBy  
  ,ISNULL(custRef.FirstName, '''') + '' '' + ISNULL(custRef.LastName, '''') AS RefferedByName  
  ,ISNULL(cust.FirstName, l.FirstName) AS FirstName  
  ,ISNULL(cust.LastName, l.LastName) AS LastName  
  ,ISNULL(NULLIF(CONCAT (  
     cust.FirstName  
     ,'' ''  
     ,cust.LastName  
     ), '' ''), CONCAT (  
    l.FirstName  
    ,'' ''  
    ,l.LastName  
    )) AS CustomerName  
  ,l.Priority  
  ,lbl.LabelName AS PriorityLabel  
  ,lbl.ColorCode AS PriorityColorCode  
  ,l.CreatedDate AS InquiryDate  
  ,l.LastContactedDate  
  ,l.CreatedBy  
  ,l.SalesmanId AS Salesman  
  ,l.Status  
  ,l.Other  
  ,ISNULL(cust.PhoneNumber, l.PhoneNumber) AS PhoneNumber  
  ,cust.EmailId AS Email  
  ,u.FirstName + '' '' + u.LastName AS SalesmanName  
  ,l.LocationID  
  ,fu.FollowUpDate  
  ,fu.FollowUpComment AS FollowUpLastComment  
  ,l.LeadSourceId  
  ,COUNT(*) OVER () AS TotalCount  
  ,0 AS RowNum  
  ,ISNULL(LKV.LookupValueName, ISNULL(l.Other, '' Other '')) AS LeadSourceName  
  ,l.CustomerId  
  ,l.LeadNumber  
  ,u.IsDeleted AS IsSalesmanDeleted  
  ,BUY.LookupValueName AS BuyingRangeValue  
  ,l.BuyingRangeValueId
  ,l.AlternateMobileNumber
  ,l.InquiryAreaRequirement
  ,l.AlternateSalesmanId
  ,l.ClientMeetingStageId
  ,l.ArchitectMeetingStageId
  ,l.LeadType
 FROM Leads l WITH (NOLOCK)  
 LEFT JOIN LookupValues LKV WITH (NOLOCK) ON l.LeadSourceId = LKV.LookupValueId  
 LEFT JOIN Labels lbl WITH (NOLOCK) ON l.Priority = lbl.LabelId  
  AND lbl.TenantId = @TenantId  
 LEFT JOIN AspNetUsers u WITH (NOLOCK) ON l.SalesmanId = u.UserId  
 LEFT JOIN Customers cust WITH (NOLOCK) ON l.CustomerId = cust.CustomerId  
  AND cust.TenantId = @TenantId  
 LEFT JOIN Customers custRef WITH (NOLOCK) ON cust.RefferedBy = custRef.CustomerId  
  AND custRef.TenantId = @TenantId  
 LEFT JOIN LookupValues BUY WITH (NOLOCK) ON l.BuyingRangeValueId = BUY.LookupValueId  
 OUTER APPLY (  
  SELECT TOP 1 FollowUpDate  
   ,FollowUpComment  
  FROM FollowUpLeads f WITH (NOLOCK)  
  WHERE f.LeadId = l.LeadId  
  ORDER BY f.FollowUpDate DESC  
  ) fu  
    '
			;
		SET @WhereQuery = N'  
    WHERE l.TenantId = @TenantId  
 AND (  
        (@StatusId IS NULL AND l.Status NOT IN (5,6))  
        OR  
        (@StatusId IS NOT NULL AND l.Status = @StatusId)  
    )  
 AND l.LocationID IS NOT NULL  
 AND EXISTS (  
  SELECT 1  
  FROM #UserLocations ul  
  WHERE ul.LocationID = l.LocationID  
  )  
 AND (  
  @IsAdmin = 1  
  OR @HasSuperAccess = 1  
  OR l.SalesmanId = @CurrentUserId  
  )  
    ';

		IF @CustomerName IS NOT NULL
			AND LTRIM(RTRIM(@CustomerName)) <> ''
			SET @WhereQuery += ' AND (cust.FirstName + '' '' + ISNULL(custRef.LastName, '''') LIKE ''%'' + @CustomerName + ''%'')';

		--IF @StatusId IS NOT NULL  
		-- SET @WhereQuery += ' AND l.Status = @StatusId';  
		IF @SalesmanId IS NOT NULL
			AND @SalesmanId <> - 1
			SET @WhereQuery += ' AND l.SalesmanId = @SalesmanId';

		IF @PhoneNumber IS NOT NULL
			SET @WhereQuery += ' AND ISNULL(cust.PhoneNumber, l.PhoneNumber) LIKE ''%'' + @PhoneNumber + ''%''';

		IF @InquiryFromDate IS NOT NULL
			SET @WhereQuery += ' AND l.CreatedDate >= @InquiryFromDate';

		IF @InquiryToDate IS NOT NULL
			SET @WhereQuery += ' AND l.CreatedDate <= @InquiryToDate';

		IF @FollowUpFromDate IS NOT NULL
			SET @WhereQuery += ' AND fu.FollowUpDate >= @FollowUpFromDate';

		IF @FollowUpToDate IS NOT NULL
			SET @WhereQuery += ' AND fu.FollowUpDate <= @FollowUpToDate';

		IF @LeadSourceId IS NOT NULL
			SET @WhereQuery += ' AND l.LeadSourceId = @LeadSourceId';

		IF @CustomerId IS NOT NULL
			SET @WhereQuery += ' AND l.CustomerId = @CustomerId';

		IF @LeadNumber IS NOT NULL
			SET @WhereQuery += ' AND l.LeadNumber LIKE ''%'' + @LeadNumber + ''%''';

		IF @PriorityId IS NOT NULL
			SET @WhereQuery += ' AND l.Priority = @PriorityId';

		IF @BuyingRangeValueId IS NOT NULL
			SET @WhereQuery += ' AND l.BuyingRangeValueId = @BuyingRangeValueId';

		IF @SortColumn = 'Priority'
		BEGIN
			SET @OrderByquery += 'l.Priority';
		END
		ELSE IF @SortColumn = 'Priority'
		BEGIN
			SET @OrderByquery += 'l.Priority';
		END
		ELSE IF @SortColumn = 'InquiryDate'
		BEGIN
			SET @OrderByquery += 'l.CreatedDate';
		END
		ELSE IF @SortColumn = 'InquiryDate'
		BEGIN
			SET @OrderByquery += 'l.CreatedDate';
		END
		ELSE IF @SortColumn = 'Status'
		BEGIN
			SET @OrderByquery += 'l.Status';
		END
		ELSE IF @SortColumn = 'Status'
		BEGIN
			SET @OrderByquery += 'l.Status';
		END
		ELSE IF @SortColumn = 'CustomerName'
		BEGIN
			SET @OrderByquery += 'ISNULL(NULLIF(CONCAT (  
       cust.FirstName  
       ,'' ''  
       ,cust.LastName  
       ), ''''), CONCAT (  
      l.FirstName  
      ,'' ''  
      ,l.LastName  
      ))';
		END
		ELSE IF @SortColumn = 'CustomerName'
		BEGIN
			SET @OrderByquery += 'ISNULL(NULLIF(CONCAT (  
       cust.FirstName  
       ,'' ''  
       ,cust.LastName  
       ), ''''), CONCAT (  
      l.FirstName  
      ,'' ''  
      ,l.LastName  
      ))';
		END
		ELSE IF @SortColumn = 'PhoneNumber'
		BEGIN
			SET @OrderByquery += 'ISNULL(cust.PhoneNumber, l.PhoneNumber)';
		END
		ELSE IF @SortColumn = 'PhoneNumber'
		BEGIN
			SET @OrderByquery += 'ISNULL(cust.PhoneNumber, l.PhoneNumber)';
		END
		ELSE IF @SortColumn = 'Salesman'
		BEGIN
			SET @OrderByquery += 'u.FirstName + '' '' + u.LastName';
		END
		ELSE IF @SortColumn = 'Salesman'
		BEGIN
			SET @OrderByquery += 'u.FirstName + '' '' + u.LastName';
		END
		ELSE IF @SortColumn = 'FollowUpDate'
		BEGIN
			SET @OrderByquery += 'fu.FollowUpDate';
		END
		ELSE IF @SortColumn = 'FollowUpDate'
		BEGIN
			SET @OrderByquery += 'fu.FollowUpDate';
		END
		ELSE IF @SortColumn = 'LeadSourceName'
		BEGIN
			SET @OrderByquery += 'ISNULL(LKV.LookupValueName, ISNULL(l.Other, ''Other''))';
		END
		ELSE IF @SortColumn = 'LeadSourceName'
		BEGIN
			SET @OrderByquery += 'ISNULL(LKV.LookupValueName, ISNULL(l.Other, ''Other''))';
		END
		ELSE IF @SortColumn = 'LeadNumber'
		BEGIN
			SET @OrderByquery += 'l.LeadNumber';
		END
		ELSE IF @SortColumn = 'UpdatedDate'
		BEGIN
			SET @OrderByquery += 'ISNULL(l.UpdatedDate, l.CreatedDate)';
		END
		ELSE
		BEGIN
			SET @OrderByquery += 'l.CreatedDate';
		END

		SET @OrderByquery += ' ' + @SortDirection;
		SET @OrderByquery += ' OFFSET(' + CAST(@PageNumber AS VARCHAR(20)) + ' - 1) * ' + CAST(@PageSize AS VARCHAR(20)) + ' ROWS FETCH NEXT ' + CAST(@PageSize AS VARCHAR(20)) + ' ROWS ONLY';
		SET @FinalQuery = @SelectQuery + @WhereQuery + @OrderByQuery;
		SET @Params = N'  
        @TenantId INT,  
        @CurrentUserId BIGINT,  
        @IsAdmin BIT,  
        @HasSuperAccess BIT,  
        @CustomerName VARCHAR(200),  
        @StatusId INT,  
        @SalesmanId BIGINT,  
        @PhoneNumber VARCHAR(50),  
        @InquiryFromDate DATE,  
        @InquiryToDate DATE,  
        @FollowUpFromDate DATE,  
        @FollowUpToDate DATE,  
        @LeadSourceId BIGINT,  
        @SortColumn VARCHAR(50),  
        @SortDirection VARCHAR(4),  
        @PageNumber INT,  
        @PageSize INT,  
  @CustomerId BIGINT,  
  @LeadNumber VARCHAR(15),  
  @PriorityId INT,  
  @BuyingRangeValueId BIGINT  
    ';

		EXEC sp_executesql @FinalQuery
			,@Params
			,@TenantId = @TenantId
			,@CurrentUserId = @CurrentUserId
			,@IsAdmin = @IsAdmin
			,@HasSuperAccess = @HasSuperAccess
			,@CustomerName = @CustomerName
			,@StatusId = @StatusId
			,@SalesmanId = @SalesmanId
			,@PhoneNumber = @PhoneNumber
			,@InquiryFromDate = @InquiryFromDate
			,@InquiryToDate = @InquiryToDate
			,@FollowUpFromDate = @FollowUpFromDate
			,@FollowUpToDate = @FollowUpToDate
			,@LeadSourceId = @LeadSourceId
			,@SortColumn = @SortColumn
			,@SortDirection = @SortDirection
			,@PageNumber = @PageNumber
			,@PageSize = @PageSize
			,@CustomerId = @CustomerId
			,@LeadNumber = @LeadNumber
			,@PriorityId = @PriorityId
			,@BuyingRangeValueId = @BuyingRangeValueId;

		DROP TABLE #UserLocations;
	END TRY

	BEGIN CATCH
		IF OBJECT_ID('tempdb..#UserLocations') IS NOT NULL
			DROP TABLE #UserLocations;

		DECLARE @ObjectName VARCHAR(500) = OBJECT_NAME(@@PROCID)
			,@ErrorMsg VARCHAR(MAX) = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

