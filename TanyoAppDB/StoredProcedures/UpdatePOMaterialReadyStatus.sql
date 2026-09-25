CREATE PROCEDURE [dbo].[UpdatePOMaterialReadyStatus] (
	@OrderSetItemId INT
	,@OrderId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- Update PO Product Items as Material Ready
		IF EXISTS (
				SELECT 1
				FROM POProductItems
				WHERE VendorOrderSetItemId = @OrderSetItemId
				)
		BEGIN
			UPDATE POProductItems
			SET Status = 5 -- MaterialReady
				,POItemMaterialReadyDate = GETDATE()
			WHERE VendorOrderSetItemId = @OrderSetItemId
		END

		-- If all PO items are Material Ready then update PO status
		IF NOT EXISTS (
				SELECT 1
				FROM POProductItems POI WITH (NOLOCK)
				INNER JOIN POProducts PO WITH (NOLOCK) ON POI.POProductId = PO.POProductId
				WHERE PO.VendorOrderId = @OrderId
					AND ISNULL(POI.Status, 0) <> 5
				)
		BEGIN
			UPDATE POProducts
			SET Status = 5 -- MaterialReady
				,POMaterialReadyDate = GETDATE()
			WHERE VendorOrderId = @OrderId
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

