/*
EXEC dbo.App_List_GetAllPendingApprovalPayments
     @SearchTerm = NULL
    ,@TenantId = 2
    ,@SortBy = 'CustomerName'
    ,@SortOrder = 'ASC'
    ,@PageNumber = 1
    ,@PageSize = 10;
*/
CREATE PROCEDURE [dbo].[App_List_GetAllPendingApprovalPayments] (
   	@SearchTerm NVARCHAR(200) = NULL
	,@TenantId INT
	,@SortBy NVARCHAR(100) = 'CustomerName'
	,@SortOrder NVARCHAR(4) = 'ASC'
	,@PageNumber INT = 1
	,@PageSize INT = 10
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT P.PaymentId
			,O.OrderId
			,O.OrderNo
			,LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, ''))) AS CustomerName
			,C.CustomerId
			,P.ReceivedAmount AS PendingReceivedAmount
			,P.PaymentType AS PaymentTypeEnum
			,OPS.StatusLabel AS PaymentTypeName
			,O.TotalAmt AS OrderAmount
			,O.TotalAmt - ISNULL(O.AdvanceAmount, 0) AS RemainingAmount
			,P.PaymentStatus AS PaymentStatus
			,O.AdvanceAmount AS TotalReceivedAmount
			,COUNT(1) OVER () AS TotalCount
		FROM Payments P WITH (NOLOCK)
		INNER JOIN Orders O WITH (NOLOCK) ON O.OrderId = P.OrderId
		INNER JOIN Customers C WITH (NOLOCK) ON C.CustomerId = O.CustomerID
			AND ISNULL(C.IsDeleted, 0) = 0
		INNER JOIN OrderPaymentStatus OPS WITH (NOLOCK) ON P.PaymentType = OPS.StatusEnumId
		WHERE P.TenantId = @TenantId
			AND ISNULL(P.IsDeleted, 0) = 0
			AND P.PaymentStatus = 0
			AND (
				@SearchTerm IS NULL
				OR O.OrderNo LIKE '%' + LTRIM(RTRIM(@SearchTerm)) + '%'
				OR LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, ''))) LIKE '%' + LTRIM(RTRIM(@SearchTerm)) + '%'
				)
		ORDER BY CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'ASC'
					THEN O.OrderNo
				END ASC
			,CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'DESC'
					THEN O.OrderNo
				END DESC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'ASC'
					THEN LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, '')))
				END ASC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'DESC'
					THEN LTRIM(RTRIM(ISNULL(C.FirstName + ' ', '') + ISNULL(C.LastName, '')))
				END DESC
			,CASE 
				WHEN @SortBy = 'ReceivedAmount'
					AND @SortOrder = 'ASC'
					THEN P.ReceivedAmount
				END ASC
			,CASE 
				WHEN @SortBy = 'ReceivedAmount'
					AND @SortOrder = 'DESC'
					THEN P.ReceivedAmount
				END DESC
			,CASE 
				WHEN @SortBy = 'PaymentMode'
					AND @SortOrder = 'ASC'
					THEN P.PaymentType
				END ASC
			,CASE 
				WHEN @SortBy = 'PaymentMode'
					AND @SortOrder = 'DESC'
					THEN P.PaymentType
				END DESC
			,CASE 
				WHEN @SortBy = 'OrderAmount'
					AND @SortOrder = 'ASC'
					THEN O.TotalAmt
				END ASC
			,CASE 
				WHEN @SortBy = 'OrderAmount'
					AND @SortOrder = 'DESC'
					THEN O.TotalAmt
				END DESC
			,CASE 
				WHEN @SortBy = 'RemainingAmount'
					AND @SortOrder = 'ASC'
					THEN O.TotalAmt - ISNULL(O.AdvanceAmount, 0)
				END ASC
			,CASE 
				WHEN @SortBy = 'RemainingAmount'
					AND @SortOrder = 'DESC'
					THEN O.TotalAmt - ISNULL(O.AdvanceAmount, 0)
				END DESC
			,CASE 
				WHEN @SortBy = 'PaymentStatus'
					AND @SortOrder = 'ASC'
					THEN P.PaymentStatus
				END ASC
			,CASE 
				WHEN @SortBy = 'PaymentStatus'
					AND @SortOrder = 'DESC'
					THEN P.PaymentStatus
				END DESC
			,P.PaymentId DESC OFFSET(@PageNumber - 1) * @PageSize ROWS

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

