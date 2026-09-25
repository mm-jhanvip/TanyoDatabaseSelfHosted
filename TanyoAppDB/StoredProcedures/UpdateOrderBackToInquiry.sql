-- =============================================
-- Author		: Smit Solanki
-- Create date	: 2026-Aug-04
-- Description	: Move order back to Inquiry status
-- =============================================
/*
	EXEC [dbo].[UpdateOrderBackToInquiry]
		@OrderId = 25
		,@TenantId = 127
		,@UserId = 4461
*/
CREATE PROCEDURE [dbo].[UpdateOrderBackToInquiry] (
	@OrderId BIGINT
	,@TenantId INT
	,@UserId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Status INT
		,@Message VARCHAR(MAX)
		,@dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@dtUTC DATETIME = GETUTCDATE();

	IF NOT EXISTS (
			SELECT 1
			FROM Orders
			WHERE OrderId = @OrderId
				AND TenantId = @TenantId
				AND Status <> 9 -- Delete
			)
	BEGIN
		SELECT - 1 AS [Status]
			,'Inquiry not found' AS [Message];

		RETURN;
	END

	BEGIN TRY
		UPDATE Orders
		SET Status = 0 -- Inquiry
			,UpdatedBy = @UserId
			,UpdatedDate = @dt
			,UpdatedUTCDate = @dtUTC
			,InquiryLastUpdatedDate = @dt
		WHERE OrderId = @OrderId
			AND TenantId = @TenantId;

		EXEC [dbo].[SaveArchive_Order] @OrderID = @OrderId
			,@UserId = @UserId;

		SET @Status = 1;
		SET @Message = 'Success';

		SELECT @Status AS [Status]
			,@Message AS [Message];
	END TRY

	BEGIN CATCH
		-- Do NOT ROLLBACK here — it rolls back the entire stack and causes Msg 266
		SET @Status = 0;

		DECLARE @ObjectName VARCHAR(500)

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @Message = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @Message;

		SELECT @Status AS [Status]
			,@Message AS [Message];
	END CATCH
END

GO

