CREATE PROCEDURE [dbo].[UpdatePOProductItemStatus] (
	@POProductItemId BIGINT
	,@Status INT
	,@UserId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		UPDATE POProductItems
		SET Status = @Status
			,TentativePOItemPickupDate = ISNULL(TentativePOItemPickupDate, GETDATE())
			,UpdatedBy = @UserId
			,UpdatedDate = SYSDATETIMEOFFSET()
			,UpdatedUTCDate = GETUTCDATE()
		WHERE POProductItemId = @POProductItemId;
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

