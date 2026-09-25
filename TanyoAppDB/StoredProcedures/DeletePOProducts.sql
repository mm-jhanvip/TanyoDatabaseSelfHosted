CREATE   PROC [dbo].[DeletePOProducts]
(
	@POProductId BIGINT
	,@TenantId BIGINT
	,@UserId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN TRAN
		
		-- Validate record exists
		IF EXISTS (
			SELECT 1
			FROM dbo.POProducts WITH (NOLOCK)
			WHERE POProductId = @POProductId
			AND TenantId = @TenantId
			AND IsDeleted = 0
		)
		BEGIN
			-- Soft delete PO
			UPDATE dbo.POProducts
			SET 
				IsDeleted = 1,
				UpdatedBy = @UserId,
				UpdatedDate = SYSDATETIMEOFFSET(),
				UpdatedUTCDate = GETUTCDATE()
			WHERE POProductId = @POProductId
			AND TenantId = @TenantId

			SELECT 'Purchase Order deleted successfully.' AS Message, 1 AS Status
		END
		ELSE
		BEGIN
			SELECT 'Purchase Order not found or already deleted.' AS Message, 0 AS Status
		END

		COMMIT TRAN

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN

		DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
		DECLARE @ErrorLine INT = ERROR_LINE()
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY()
		DECLARE @ErrorState INT = ERROR_STATE()

		RAISERROR('DeletePOProducts failed: %s (Line %d)', @ErrorSeverity, @ErrorState, @ErrorMsg, @ErrorLine)
	END CATCH
END

GO

