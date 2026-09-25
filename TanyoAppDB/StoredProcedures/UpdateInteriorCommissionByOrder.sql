CREATE PROCEDURE [dbo].[UpdateInteriorCommissionByOrder]
(
	@OrderID BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		UPDATE os
		SET InteriorCommission = x.InteriorCommission
		FROM OrderSetItems os
		CROSS APPLY dbo.fn_CalculateInteriorCommission (@OrderID) x
		WHERE os.OrderSetItemId = x.OrderSetItemId
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

