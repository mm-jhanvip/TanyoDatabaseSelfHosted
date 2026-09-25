CREATE PROCEDURE [dbo].[UpdatePOProductStatus] (
	@POProductId BIGINT
	,@Status INT
	,@UserId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		UPDATE POProducts
		SET Status = @Status
			,TentativePOPickupDate = ISNULL(TentativePOPickupDate, GETDATE())
			,UpdatedBy = @UserId
			,UpdatedDate = SYSDATETIMEOFFSET()
			,UpdatedUTCDate = GETUTCDATE()
		WHERE POProductId = @POProductId;
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

