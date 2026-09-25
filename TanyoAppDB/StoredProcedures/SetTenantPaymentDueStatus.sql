CREATE PROCEDURE [dbo].[SetTenantPaymentDueStatus]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION SetTenantPaymentDueStatus;

		UPDATE T
		SET IsPaymentDue = CASE 
				WHEN CAST(P.UpcomingDueDate AS DATE) < CAST(GETDATE() AS DATE)
					THEN 1
				ELSE 0
				END
		FROM Tenants T
		INNER JOIN (
			SELECT TenantId
				,UpcomingDueDate
				,ROW_NUMBER() OVER (
					PARTITION BY TenantId ORDER BY TenantRecordPaymentId DESC
					) AS RN
			FROM TenantRecordPayment
			WHERE IsDeleted = 0
			) P ON T.TenantId = P.TenantId
		WHERE P.RN = 1;

		COMMIT TRANSACTION SetTenantPaymentDueStatus;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION SetTenantPaymentDueStatus;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

