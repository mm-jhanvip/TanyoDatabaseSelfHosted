/*
	EXEC dbo.UpdateOrderSetItemDirectDiscount
		@OrderID = 0
		,@OrderSetItemID = 0
		,@DiscountPercentage = 0.00
		,@UserID = 0
		,@TenantID = 0
		,@IsSQFTProduct = 0
		,@PerSQFTUnitPrice = 0
*/
CREATE PROC [dbo].[UpdateOrderSetItemDirectDiscount] (
	@OrderID BIGINT
	,@OrderSetItemID BIGINT
	,@DirectAmount NUMERIC(18, 2)
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
		DECLARE @GSTType BIT
			,@DateUtc DATETIME = GETUTCDATE()
			,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@UpdatedInstantUnitPrice NUMERIC(18, 2)

		SELECT @GSTType = o.GSTType
		FROM dbo.Orders o WITH (NOLOCK)
		WHERE o.OrderId = @OrderID

		SELECT @UpdatedInstantUnitPrice = IIF(@IsSQFTProduct = 1, @PerSQFTUnitPrice, osi.InstantUnitPrice)
		FROM dbo.OrderSetItems osi WITH (NOLOCK)
		WHERE osi.OrderSetItemId = @OrderSetItemID
			AND osi.OrderId = @OrderID

		IF (@GSTType IS NOT NULL)
		BEGIN
			UPDATE osi
			SET osi.DiscountPrice = 0.00
				,osi.Discount = 0.00
				,osi.GrossTotal = ROUND(CAST((@DirectAmount * osi.Quantity) AS NUMERIC(18, 2)), 0)
				,osi.TotalAmount = ROUND(CAST((@DirectAmount * osi.Quantity) AS NUMERIC(18, 2)), 0)
				,osi.UnitPrice = @DirectAmount
				,osi.InstantUnitPrice = @UpdatedInstantUnitPrice
				,osi.UpdatedBy = @UserID
				,osi.UpdatedDate = @DateOffset
				,osi.UpdatedUTCDate = @DateUtc
			FROM dbo.OrderSetItems osi WITH (NOLOCK)
			WHERE osi.OrderSetItemId = @OrderSetItemID
				AND osi.OrderId = @OrderID

			--UPDATE osi
			--SET osi.TotalAmount = osi.GrossTotal - (osi.GrossTotal - (ROUND(CAST((@DirectAmount * osi.Quantity) AS NUMERIC(18, 2)), 0)))
			--FROM dbo.OrderSetItems osi WITH (NOLOCK)
			--WHERE osi.OrderSetItemId = @OrderSetItemID
			--AND osi.OrderId = @OrderID
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

