/*
EXEC dbo.GetOfferActivityLog
    @OfferId = 168,
    @TenantId = 2,
    @PageIndex = 1,
    @PageSize = 10,
    @SortBy = 'CreatedByName',
    @SortOrder = 'DESC';
*/
CREATE PROCEDURE [dbo].[GetOfferActivityLog] 
     @OfferId BIGINT
	,@TenantId INT
	,@PageIndex INT = 1
	,@PageSize INT = 100
	,@SortBy VARCHAR(50) = 'CreatedByName'
	,@SortOrder VARCHAR(4) = 'DESC'
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @SubjectTypeId INT;

		SELECT @SubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Offer'
			AND TenantId = @TenantId

		SELECT al.ActivityLogID
			,al.Description
			,al.Action
			,al.CreatedBy
			,u.FirstName + ' ' + u.LastName AS CreatedByName
			,al.CreatedDate
			,COUNT(1) OVER () AS TotalCount
		FROM ActivityLogs al WITH (NOLOCK)
		INNER JOIN AspNetUsers u WITH (NOLOCK) ON al.CreatedBy = u.UserId
		WHERE al.SubjectTypeId = @SubjectTypeId
			AND al.SubjectId = @OfferId
		ORDER BY CASE 
				WHEN @SortBy = 'Description'
					AND @SortOrder = 'ASC'
					THEN al.Description
				END ASC
			,CASE 
				WHEN @SortBy = 'Description'
					AND @SortOrder = 'DESC'
					THEN al.Description
				END DESC
			,CASE 
				WHEN @SortBy = 'Action'
					AND @SortOrder = 'ASC'
					THEN al.Action
				END ASC
			,CASE 
				WHEN @SortBy = 'Action'
					AND @SortOrder = 'DESC'
					THEN al.Action
				END DESC
			,CASE 
				WHEN @SortBy = 'CreatedByName'
					AND @SortOrder = 'ASC'
					THEN u.FirstName + ' ' + u.LastName
				END ASC
			,CASE 
				WHEN @SortBy = 'CreatedByName'
					AND @SortOrder = 'DESC'
					THEN u.FirstName + ' ' + u.LastName
				END DESC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'ASC'
					THEN al.CreatedDate
				END ASC
			,CASE 
				WHEN @SortBy = 'CreatedDate'
					AND @SortOrder = 'DESC'
					THEN al.CreatedDate
				END DESC
			,al.CreatedDate DESC OFFSET(@PageIndex - 1) * @PageSize ROWS

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

