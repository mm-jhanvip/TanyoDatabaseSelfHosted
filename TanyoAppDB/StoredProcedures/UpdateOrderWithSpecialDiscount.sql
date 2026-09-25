CREATE PROC [dbo].[UpdateOrderWithSpecialDiscount] (
	@OrderID BIGINT
	,@UserID BIGINT
	,@TenantID BIGINT
	,@Status BIT = 0 OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @DateUtc DATETIME = GETUTCDATE()
			,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
		DECLARE @GSTType BIT
			,@SpecialDiscount NUMERIC(18, 2) = 0

		SELECT @GSTType = o.GSTType
			,@SpecialDiscount = o.SpecialDiscount
		FROM dbo.Orders o WITH (NOLOCK)
		WHERE o.OrderId = @OrderID

		IF @SpecialDiscount > 0
		BEGIN
			IF ISNULL(@GSTType, 0) = 0
			BEGIN
				UPDATE ORD
				SET ORD.AmountBeforeGST = CAST(((ORD.TotalAmount - ORD.SpecialDiscount) * 100) / (118) AS NUMERIC(18, 2))
					,ORD.CGSTAmount = CAST((((ORD.TotalAmount - ORD.SpecialDiscount) * 18) / (118)) / 2 AS NUMERIC(18, 2))
					,ORD.SGSTAmount = CAST((((ORD.TotalAmount - ORD.SpecialDiscount) * 18) / (118)) / 2 AS NUMERIC(18, 2))
					,ORD.UpdatedBy = @UserID
					,ORD.UpdatedDate = @DateOffset
					,ORD.UpdatedUTCDate = @DateUtc
					,ord.TotalAmount = ORD.TotalAmount - ORD.SpecialDiscount
				FROM Orders ORD
				WHERE ORD.OrderId = @OrderID
			END
			ELSE
			BEGIN
				UPDATE ORD
				SET ORD.AmountBeforeGST = CAST(ORD.TotalAmount - ORD.SpecialDiscount AS NUMERIC(18, 2))
					,ORD.CGSTAmount = CAST((((ORD.TotalAmount - ORD.SpecialDiscount) * 18) / 100) / 2 AS NUMERIC(18, 2))
					,ORD.SGSTAmount = CAST((((ORD.TotalAmount - ORD.SpecialDiscount) * 18) / 100) / 2 AS NUMERIC(18, 2))
					,ORD.UpdatedBy = @UserID
					,ORD.UpdatedDate = @DateOffset
					,ORD.UpdatedUTCDate = @DateUtc
					,ORD.TotalAmount = ORD.TotalAmount - ORD.SpecialDiscount
				FROM Orders ORD
				WHERE ORD.OrderId = @OrderID
			END
		END

		SET @Status = 1
	END TRY

	BEGIN CATCH
		SET @Status = 0

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

