/*
	EXEC dbo.UpdateOrderStatusDelivered
		@OrderNo = 'W17742-17052023'
*/
CREATE PROC [dbo].[UpdateOrderStatusDelivered] 
(
@OrderNo VARCHAR(100)
)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		DECLARE @OrderId BIGINT
		DECLARE @TenantId BIGINT
		DECLARE @SubjectTypeId BIGINT
		DECLARE @DeliveryDate DATE = CAST(GETDATE() AS DATE)
		DECLARE @CreatedDate DATETIMEOFFSET = SWITCHOFFSET(SYSDATETIMEOFFSET(), '+05:30')
		DECLARE @ActivityDescription NVARCHAR(MAX)
		DECLARE @CreatedUTCDate DATETIME = GETUTCDATE()

		SELECT @OrderId = o.OrderId
			,@TenantId = o.TenantId
		FROM dbo.Orders o WITH (NOLOCK)
		WHERE o.OrderNo = @OrderNo

		SELECT @SubjectTypeId = st.SubjectTypeId
		FROM dbo.SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantId
			AND st.SubjectTypeName = 'Orders'

		IF (@OrderId IS NOT NULL)
		BEGIN
			BEGIN TRANSACTION UpdateOrderStatusDelivered

			UPDATE o
			SET o.Status = 5 --Deliverd
				,o.DeliveryDate = @DeliveryDate
			FROM dbo.Orders o
			WHERE o.OrderId = @OrderId

			UPDATE osi
			SET osi.ItemStatus = 3 --Deliverd
				,osi.DeliveryDate = @DeliveryDate
			FROM dbo.OrderSetItems osi
			WHERE osi.OrderId = @OrderId

			SET @ActivityDescription = 'Order status has been changed to Delivered. - By System User on ' + FORMAT(@CreatedDate, 'dd/MM/yyyy hh:mm tt')

			EXEC dbo.SaveActivityLog @SubjectTypeId = @SubjectTypeId
				,@SubjectId = @OrderId
				,@Description = @ActivityDescription
				,@Action = 'UPDATE'
				,@CreatedBy = 3183
				,@CreatedDate = @CreatedDate
				,@CreatedUTCDate = @CreatedUTCDate

			COMMIT TRANSACTION UpdateOrderStatusDelivered
		END
	END TRY

	BEGIN CATCH
		SELECT ERROR_MESSAGE()

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION UpdateOrderStatusDelivered

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

