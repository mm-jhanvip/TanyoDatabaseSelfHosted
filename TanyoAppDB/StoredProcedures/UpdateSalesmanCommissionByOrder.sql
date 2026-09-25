CREATE PROCEDURE [dbo].[UpdateSalesmanCommissionByOrder] 
(
@OrderID BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		UPDATE os
		SET SalesmanCommission = x.SalesmanCommission
		FROM OrderSetItems os
		CROSS APPLY dbo.fn_CalculateSalesmanCommission(@OrderID) x
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

