/*    
  EXEC [dbo].[ListLeadPipeline]    
    @PipelineType = 1,    
    @TenantId = 192,    
    @CustomerName = NULL,    
    @PhoneNumber = NULL,    
    @StatusId = NULL,    
    @SalesmanId = NULL,    
    @LeadSourceId = NULL,    
    @InquiryFromDate = NULL,    
    @InquiryToDate = NULL,    
    @BuyingRangeValueId = NULL,    
    @LeadNumber = NULL,    
    @PageNumber = 1,    
    @PageSize = 10,    
    @SortBy = 'UpdatedDate',    
    @SortOrder = 'DESC'    
*/
CREATE PROCEDURE [dbo].[ListLeadPipeline] (
	@PipelineType INT
	,@TenantId INT
	,@CustomerName VARCHAR(200) = NULL
	,@PhoneNumber VARCHAR(50) = NULL
	,@StatusId INT = NULL
	,@SalesmanId BIGINT = NULL
	,@LeadSourceId BIGINT = NULL
	,@InquiryFromDate DATE = NULL
	,@InquiryToDate DATE = NULL
	,@BuyingRangeValueId BIGINT = NULL
	,@LeadNumber VARCHAR(15) = NULL
	,@PageNumber INT = 1
	,@PageSize INT = 10
	,@SortBy VARCHAR(50) = 'UpdatedDate'
	,@SortOrder VARCHAR(4) = 'DESC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @LeadTypeFilter INT = CASE @PipelineType
				WHEN 1
					THEN 0
				WHEN 2
					THEN 0
				WHEN 3
					THEN 1
				WHEN 4
					THEN 1
				END;
		DECLARE @IsFieldPipeline BIT = CASE 
				WHEN @PipelineType IN (
						1
						,4
						)
					THEN 1
				ELSE 0
				END;

		SELECT l.LeadId
			,ISNULL(RTRIM(LTRIM(CONCAT (
							l.FirstName
							,' '
							,l.LastName
							))), '') AS CustomerName
			,l.FirstName
			,l.LastName
			,l.Status
			,l.SalesmanId AS Salesman
			,ISNULL(RTRIM(LTRIM(CONCAT (
							u.FirstName
							,' '
							,u.LastName
							))), '') AS SalesmanName
			,l.Notes AS Inquiry
			,l.InquiryAbout
			,NULL AS CategoryName
			,l.PhoneNumber
			,l.CreatedDate AS InquiryDate
			,l.LastContactedDate
			,l.Email
			,l.Priority
			,ISNULL(p.ColorCode, '') AS PriorityColorCode
			,ISNULL(p.LabelName, '') AS PriorityLabel
			,l.CreatedBy
			,l.Other
			,l.LocationID
			,l.InquiryFor
			,l.RefferedBy
			,ISNULL(RTRIM(LTRIM(CONCAT (
							ref.FirstName
							,' '
							,ref.LastName
							))), '') AS RefferedByName
			,fu.FollowUpDate
			,fu.FollowUpComment AS FollowUpLastComment
			,l.LeadSourceId
			,l.CustomerId
			,l.LeadNumber
			,CAST(CASE 
					WHEN u.IsDeleted = 1
						THEN 1
					ELSE 0
					END AS BIT) AS IsSalesmanDeleted
			,br.LookupValueName AS BuyingRangeValue
			,l.BuyingRangeValueId
			,CASE @PipelineType
				WHEN 1
					THEN 'Field Pipeline'
				WHEN 2
					THEN 'Sales Pipeline'
				WHEN 3
					THEN 'Architects Visit - Store'
				WHEN 4
					THEN 'Architects Visit - Field'
				END AS PipelineName
			,COUNT(1) OVER () AS TotalCount
		FROM Leads l WITH (NOLOCK)
		INNER JOIN AspNetUsers u WITH (NOLOCK) ON l.SalesmanId = u.UserId
		LEFT JOIN Labels p WITH (NOLOCK) ON l.Priority = p.LabelId
			AND p.TenantId = @TenantId
		LEFT JOIN AspNetUsers ref WITH (NOLOCK) ON l.RefferedBy = ref.UserId
		LEFT JOIN LookupValues br WITH (NOLOCK) ON l.BuyingRangeValueId = br.LookupValueId
		OUTER APPLY (
			SELECT TOP 1 fu1.FollowUpDate
				,fu1.FollowUpComment
			FROM FollowUpLeads fu1 WITH (NOLOCK)
			WHERE fu1.LeadId = l.LeadId
			ORDER BY fu1.FollowUpDate DESC
			) fu
		WHERE l.TenantId = @TenantId
			AND l.Status <> 6
			AND l.LeadType = @LeadTypeFilter
			AND (
				(
					@IsFieldPipeline = 1
					AND u.FieldStoreOperationType = 1
					)
				OR (
					@IsFieldPipeline = 0
					AND u.FieldStoreOperationType IN (
						2
						,3
						)
					)
				)
			AND (
				@CustomerName IS NULL
				OR @CustomerName = ''
				OR (l.FirstName + ' ' + ISNULL(l.LastName, '')) LIKE '%' + @CustomerName + '%'
				)
			AND (
				@PhoneNumber IS NULL
				OR @PhoneNumber = ''
				OR l.PhoneNumber LIKE '%' + @PhoneNumber + '%'
				)
			AND (
				@StatusId IS NULL
				OR l.Status = @StatusId
				)
			AND (
				@SalesmanId IS NULL
				OR l.SalesmanId = @SalesmanId
				)
			AND (
				@LeadSourceId IS NULL
				OR l.LeadSourceId = @LeadSourceId
				)
			AND (
				@InquiryFromDate IS NULL
				OR CAST(l.CreatedDate AS DATE) >= @InquiryFromDate
				)
			AND (
				@InquiryToDate IS NULL
				OR CAST(l.CreatedDate AS DATE) <= @InquiryToDate
				)
			AND (
				@BuyingRangeValueId IS NULL
				OR l.BuyingRangeValueId = @BuyingRangeValueId
				)
			AND (
				@LeadNumber IS NULL
				OR @LeadNumber = ''
				OR l.LeadNumber LIKE '%' + @LeadNumber + '%'
				)
		ORDER BY CASE 
				WHEN @SortOrder = 'ASC'
					AND @SortBy = 'CustomerName'
					THEN l.FirstName + ' ' + ISNULL(l.LastName, '')
				END ASC
			,CASE 
				WHEN @SortOrder = 'DESC'
					AND @SortBy = 'CustomerName'
					THEN l.FirstName + ' ' + ISNULL(l.LastName, '')
				END DESC
			,CASE 
				WHEN @SortOrder = 'ASC'
					AND @SortBy = 'SalesmanName'
					THEN u.FirstName + ' ' + u.LastName
				END ASC
			,CASE 
				WHEN @SortOrder = 'DESC'
					AND @SortBy = 'SalesmanName'
					THEN u.FirstName + ' ' + u.LastName
				END DESC
			,CASE 
				WHEN @SortOrder = 'ASC'
					AND @SortBy = 'UpdatedDate'
					THEN l.UpdatedDate
				END ASC
			,CASE 
				WHEN @SortOrder = 'DESC'
					AND @SortBy = 'UpdatedDate'
					THEN l.UpdatedDate
				END DESC
			,l.UpdatedDate DESC 
			
			OFFSET(@PageNumber - 1) * @PageSize ROWS
			FETCH NEXT @PageSize ROWS ONLY
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

