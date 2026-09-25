CREATE PROC [dbo].[UpdateOrderGST] (
	@OrderID BIGINT
	,@GSTType BIT
	,@UserID BIGINT
	,@TenantID BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	-- @GSTType = 0 then it's Inclusive
	-- @GSTType = 1 then it's Exclusive
	BEGIN TRY
		IF EXISTS (
				SELECT 1
				FROM dbo.Orders o WITH (NOLOCK)
				WHERE o.OrderId = @OrderID
				)
		BEGIN
			DECLARE @DateUtc DATETIME = GETUTCDATE()
				,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()

			--Update Amounts in OrderSetItems
			IF @GSTType = 0
			BEGIN
				UPDATE osi
				SET osi.AmountBeforeGST = CAST((osi.TotalAmount * 100) / (100 + osi.GST) AS NUMERIC(18, 2))
					,osi.CGSTAmount = CAST(((osi.TotalAmount * osi.GST) / (100 + osi.GST)) / 2 AS NUMERIC(18, 2))
					,osi.SGSTAmount = CAST(((osi.TotalAmount * osi.GST) / (100 + osi.GST)) / 2 AS NUMERIC(18, 2))
					,osi.UpdatedBy = @UserID
					,osi.UpdatedDate = @DateOffset
					,osi.UpdatedUTCDate = @DateUtc
				FROM dbo.OrderSetItems osi
				WHERE osi.OrderId = @OrderID
					AND osi.IsDeleted = 0
			END
			ELSE
			BEGIN
				UPDATE osi
				SET osi.AmountBeforeGST = CAST(osi.TotalAmount AS NUMERIC(18, 2))
					,osi.CGSTAmount = CAST(((osi.TotalAmount * osi.GST) / 100) / 2 AS NUMERIC(18, 2))
					,osi.SGSTAmount = CAST(((osi.TotalAmount * osi.GST) / 100) / 2 AS NUMERIC(18, 2))
					,osi.UpdatedBy = @UserID
					,osi.UpdatedDate = @DateOffset
					,osi.UpdatedUTCDate = @DateUtc
				FROM dbo.OrderSetItems osi
				WHERE osi.OrderId = @OrderID
					AND osi.IsDeleted = 0
			END
					--Update Amounts in Orders
					;

			WITH cte
			AS (
				SELECT o.OrderId
					,GrossTotal = ISNULL(SUM(osi.GrossTotal), 0)
					,Discount = ISNULL(SUM(osi.Discount), 0)
					,TotalAmount = ISNULL(SUM(osi.TotalAmount), 0)
					,AmountBeforeGST = ISNULL(SUM(osi.AmountBeforeGST), 0)
					,CGSTAmount = ISNULL(SUM(osi.CGSTAmount), 0)
					,SGSTAmount = ISNULL(SUM(osi.SGSTAmount), 0)
				FROM dbo.Orders o
				LEFT JOIN dbo.OrderSetItems osi WITH (NOLOCK) ON osi.OrderId = o.OrderId
					AND osi.IsDeleted = 0
				WHERE o.OrderId = @OrderId
				GROUP BY o.OrderId
				)
			UPDATE o
			SET o.GrossTotal = c.GrossTotal
				,o.Discount = c.Discount
				,o.TotalAmount = c.TotalAmount
				,o.AmountBeforeGST = c.AmountBeforeGST
				,o.CGSTAmount = c.CGSTAmount
				,o.SGSTAmount = c.SGSTAmount
				,o.GSTType = @GSTType
				,o.UpdatedBy = @UserID
				,o.UpdatedDate = @DateOffset
				,o.UpdatedUTCDate = @DateUtc
			FROM cte c
			INNER JOIN dbo.Orders o WITH (NOLOCK) ON o.OrderId = c.OrderId
			WHERE o.OrderId = @OrderID

			EXEC dbo.UpdateOrderWithSpecialDiscount @OrderID = @OrderID
				,@UserID = @UserID
				,@TenantID = @TenantID

			--Return Order
			SELECT *
			FROM dbo.Orders o WITH (NOLOCK)
			WHERE o.OrderId = @OrderID
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

