/*
	EXEC [dbo].[GetAllNotificationsByTenantId]
		@TenantId  = 2
		,@ApplicationType  = 1
		,@PageIndex = 1
		,@PageSize = 25	
*/
CREATE PROCEDURE [dbo].[GetAllNotificationsByTenantId]
(@TenantId INT 
,@ApplicationType  INT = NULL
,@PageIndex INT = 1
,@PageSize INT = 25
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
			SELECT n.NotificationId
			 ,n.Message
			 ,n.CreatedDate
			 ,n.EntityId
			 ,n.IsRead
			 ,COUNT(1) OVER () AS TotalCount
			FROM Notifications n WITH (NOLOCK)
			WHERE n.TenantId = @TenantId
			AND n.ApplicationType = @ApplicationType
			ORDER BY n.CreatedDate DESC
			OFFSET(@PageIndex - 1) * @PageSize ROWS
				FETCH NEXT @PageSize ROWS ONLY
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

