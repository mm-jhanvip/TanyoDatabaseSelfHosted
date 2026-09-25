CREATE PROCEDURE [dbo].[UpdateSalesmanCommission]
(
	@OrderID BIGINT
	,@SalesmanCommissionPer NUMERIC(5,2)
	,@ActivityMessage VARCHAR(100)
	,@TenantID INT
	,@UserID INT
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @Result NVARCHAR (MAX)
		DECLARE @OrderSubjectTypeId INT
		DECLARE @dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
		DECLARE @dtUTC DATETIME = GETUTCDATE()

		SELECT @OrderSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'Orders'

		UPDATE Orders
		SET SalesmanCommissionPer = @SalesmanCommissionPer
		WHERE OrderId = @OrderID

		DECLARE @SalesmanCommission TABLE
		(
			OrderSetItemId BIGINT
			,SalesmanCommission NUMERIC(18,2)
		)

		INSERT INTO @SalesmanCommission
		(
			OrderSetItemId
			,SalesmanCommission
		)
		SELECT x.OrderSetItemId
			,x.SalesmanCommission
		FROM dbo.fn_CalculateSalesmanCommission(@OrderID) x

		UPDATE OrderSetItems
		SET SalesmanCommission = x.SalesmanCommission
		FROM OrderSetItems os
		INNER JOIN @SalesmanCommission x ON x.OrderSetItemId = os.OrderSetItemId

		EXEC dbo.SaveActivityLog 
			 @SubjectTypeId = @OrderSubjectTypeId
			,@SubjectId = @OrderID
			,@Description = @ActivityMessage
			,@Action = 'UPDATE'
			,@CreatedBy = @UserID
			,@CreatedDate = @dt
			,@CreatedUTCDate = @dtUTC;

		IF @@ROWCOUNT > 0
		BEGIN
			SET @Result = 'Successfully Updated'
		END
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

