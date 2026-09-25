/*
	EXEC dbo.UpdateOrderSetItemDiscount
		@OrderID = 0
		,@OrderSetItemID = 0
		,@DiscountPercentage = 0.00
		,@UserID = 0
		,@TenantID = 0
		,@IsSQFTProduct = 0
		,@PerSQFTUnitPrice = 0
*/
CREATE PROC [dbo].[UpdateOrderSetItemDiscount] (
	@OrderID BIGINT
	,@OrderSetItemID BIGINT
	,@DiscountPercentage NUMERIC(18, 2)
	,@UserID BIGINT
	,@TenantID BIGINT
	,@IsSQFTProduct BIT = 0
	,@PerSQFTUnitPrice NUMERIC(18, 2) = 0
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF EXISTS (
				SELECT 1
				FROM dbo.Orders o WITH (NOLOCK)
				WHERE o.OrderId = @OrderID
				)
		BEGIN
			DECLARE @GSTType BIT
				,@DateUtc DATETIME = GETUTCDATE()
				,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()

			SELECT @GSTType = o.GSTType
			FROM dbo.Orders o WITH (NOLOCK)
			WHERE o.OrderId = @OrderID

			UPDATE osi
			SET osi.DiscountPrice = @DiscountPercentage
				,osi.InstantUnitPrice = IIF(@IsSQFTProduct = 1, @PerSQFTUnitPrice, osi.InstantUnitPrice)
				,osi.Discount = ROUND(CAST(((osi.UnitPrice * @DiscountPercentage) / 100) * osi.Quantity AS NUMERIC(18, 2)), 0)
				,osi.TotalAmount = ROUND(CAST((osi.UnitPrice - ((osi.UnitPrice * @DiscountPercentage) / 100)) * osi.Quantity AS NUMERIC(18, 2)), 0)
				,osi.UnitSalePrice = CAST((osi.UnitPrice - ROUND((osi.UnitPrice * @DiscountPercentage) / 100, 2)) AS NUMERIC(18, 2))
				,osi.UpdatedBy = @UserID
				,osi.UpdatedDate = @DateOffset
				,osi.UpdatedUTCDate = @DateUtc
			FROM dbo.OrderSetItems osi
			WHERE osi.OrderSetItemId = @OrderSetItemID
				AND osi.OrderId = @OrderID

			--Update GST Calculation
			EXEC dbo.UpdateOrderGST @OrderID = @OrderID
				,@GSTType = @GSTType
				,@UserID = @UserID
				,@TenantID = @TenantID

			EXEC dbo.SaveArchive_Order @OrderID = @OrderID
				,@UserID = @UserID
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

