CREATE PROCEDURE [dbo].[UpdateInteriorCommission] (
	@OrderID BIGINT
	,@InteriorCommissionPer NUMERIC(5, 2)
	,@ActivityMessage VARCHAR(100)
	,@TenantID INT
	,@UserID INT
	)
WITH ENCRYPTION
AS
BEGIN TRY
	BEGIN
		SET NOCOUNT ON;

		DECLARE @Result NVARCHAR(MAX)
		DECLARE @OrderSubjectTypeId INT
		DECLARE @CreatedDate DATETIMEOFFSET = SYSDATETIMEOFFSET()
		DECLARE @CreatedUTCDate DATETIME = GETUTCDATE()

		SELECT @OrderSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
			AND st.SubjectTypeName = 'Orders'

		UPDATE Orders
		SET InteriorCommissionPer = @InteriorCommissionPer
		WHERE OrderId = @OrderID

		UPDATE OrderSetItems
		SET InteriorCommission = x.InteriorCommission
		FROM OrderSetItems os
		CROSS APPLY dbo.fn_CalculateInteriorCommission(@OrderID) x
		WHERE os.OrderSetItemId = x.OrderSetItemId

		EXEC dbo.SaveActivityLog @SubjectTypeId = @OrderSubjectTypeId
			,@SubjectId = @OrderID
			,@Description = @ActivityMessage
			,@Action = 'UPDATE'
			,@CreatedBy = @UserID
			,@CreatedDate = @CreatedDate
			,@CreatedUTCDate = @CreatedUTCDate;

		IF @@ROWCOUNT > 0
		BEGIN
			SET @Result = 'Successfully Updated'
		END
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

GO

