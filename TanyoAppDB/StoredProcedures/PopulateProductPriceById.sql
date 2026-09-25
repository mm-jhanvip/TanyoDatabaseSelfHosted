/*
    DECLARE @Status INT
            ,@Message VARCHAR(500)

    EXEC dbo.PopulateProductPriceById
        @ProductId = 1001
        ,@UserId = 1
        ,@TenantId = 2
        ,@CostPrice = 100
        ,@RetailerPrice = 120
        ,@WholesalerPrice = 110
        ,@IsPriceAutoCalculated = 1
        ,@Status = @Status OUTPUT
        ,@Message = @Message OUTPUT
        ,@ShouldUpdateInquiries = 0
        ,@AffectedInquiriesCount = 0

    SELECT @Status AS Status
           ,@Message AS Message
*/
CREATE PROCEDURE [dbo].[PopulateProductPriceById] (
	@ProductId BIGINT
	,@TenantId BIGINT
	,@UserId BIGINT
	,@CostPrice NUMERIC(18, 2)
	,@RetailerPrice NUMERIC(18, 2)
	,@WholesalerPrice NUMERIC(18, 2)
	,@IsPriceAutoCalculated BIT
	,@Status INT OUTPUT
	,@Message VARCHAR(500) OUTPUT
	,@ShouldUpdateInquiries BIT = 0
	,@AffectedInquiriesCount INT = 0
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF NOT EXISTS (
				SELECT 1
				FROM Products p WITH (NOLOCK)
				WHERE p.ProductId = @ProductId
					AND p.TenantId = @TenantId
				)
		BEGIN
			SET @Status = - 1;
			SET @Message = 'Product does not exist.';

			RETURN
		END

		DECLARE @DtNowOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DtNowUTC DATETIME = GETUTCDATE()
			,@Description VARCHAR(MAX) = ''
		DECLARE @ProductSubjectTypeId INT
			,@OldCostPrice NUMERIC(18, 2)
			,@OldRetailerPrice NUMERIC(18, 2)
			,@OldWholesalerPrice NUMERIC(18, 2)
			,@OldIsPriceAutoCalculated BIT
			,@CategoryId INT
			,@CategoryRetailerPercentage DECIMAL(18, 2)
			,@CategoryWholesalePercentage DECIMAL(18, 2)
			,@CalculatedRetailerPrice NUMERIC(18, 2)
			,@CalculatedWholesalerPrice NUMERIC(18, 2)
			,@RoundedRetailerPrice NUMERIC(18, 2)
			,@RoundedWholesalerPrice NUMERIC(18, 2)
			,@TenantAmountRoundMultiple INT

		SELECT @ProductSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.SubjectTypeName = 'Products'
			AND st.TenantId = @TenantId

		SELECT @TenantAmountRoundMultiple = AmountRoundMultiple
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId

		SELECT @OldCostPrice = p.CostPrice
			,@OldRetailerPrice = p.RetailerPrice
			,@OldWholesalerPrice = p.WholesalerPrice
			,@OldIsPriceAutoCalculated = p.IsPriceAutoCalculated
			,@CategoryId = p.CategoryId
		FROM Products p WITH (UPDLOCK)
		WHERE p.ProductId = @ProductId
			AND p.TenantId = @TenantId

		-- Auto Price calculation based on Product Category Percentage and Rounding
		IF @IsPriceAutoCalculated = 1
		BEGIN
			SET @CategoryRetailerPercentage = 0
			SET @CategoryWholesalePercentage = 0
			SET @CalculatedRetailerPrice = 0
			SET @CalculatedWholesalerPrice = 0
			SET @RoundedRetailerPrice = 0
			SET @RoundedWholesalerPrice = 0

			--Get product category percentage
			SELECT @CategoryRetailerPercentage = RSPPercentage
				,@CategoryWholesalePercentage = WSPPercentage
			FROM Categories c WITH (NOLOCK)
			WHERE c.CategoryId = @CategoryId
				AND c.TenantId = @TenantId

			--Calculate Retailer Price based on category percentage
			IF @CategoryRetailerPercentage > 0
			BEGIN
				SET @CalculatedRetailerPrice = @CostPrice + (@CostPrice * @CategoryRetailerPercentage / 100);
			END
			ELSE
			BEGIN
				SET @CalculatedRetailerPrice = @CostPrice
			END

			--Calculate Wholesaler Price based on category percentage
			IF @CategoryWholesalePercentage > 0
			BEGIN
				SET @CalculatedWholesalerPrice = @CostPrice + (@CostPrice * @CategoryWholesalePercentage / 100);
			END
			ELSE
			BEGIN
				SET @CalculatedWholesalerPrice = @CostPrice
			END

			--Apply Rounding on Calculated Retailer Price
			SET @RoundedRetailerPrice = CAST(ROUND(CASE 
							WHEN @TenantAmountRoundMultiple > 0
								THEN @TenantAmountRoundMultiple * ROUND(@CalculatedRetailerPrice / @TenantAmountRoundMultiple, 0)
							ELSE @CalculatedRetailerPrice
							END, 0) AS NUMERIC(18, 0))
			--Apply Rounding on Calculated Wholesaler Price
			SET @RoundedWholesalerPrice = CAST(ROUND(CASE 
							WHEN @TenantAmountRoundMultiple > 0
								THEN @TenantAmountRoundMultiple * ROUND(@CalculatedWholesalerPrice / @TenantAmountRoundMultiple, 0)
							ELSE @CalculatedWholesalerPrice
							END, 0) AS NUMERIC(18, 0))

			UPDATE p
			SET p.CostPrice = @CostPrice
				,p.RetailerPrice = @RoundedRetailerPrice
				,p.WholesalerPrice = @RoundedWholesalerPrice
				,p.IsPriceAutoCalculated = @IsPriceAutoCalculated
				,p.UpdatedBy = @UserId
				,p.UpdatedDate = @DtNowOffset
				,p.UpdatedUTCDate = @DtNowUTC
			FROM Products p
			WHERE p.ProductId = @ProductId
				AND p.TenantId = @TenantId
		END
		ELSE
		BEGIN
			UPDATE p
			SET p.CostPrice = @CostPrice
				,p.RetailerPrice = @RetailerPrice
				,p.WholesalerPrice = @WholesalerPrice
				,p.IsPriceAutoCalculated = @IsPriceAutoCalculated
				,p.UpdatedBy = @UserId
				,p.UpdatedDate = @DtNowOffset
				,p.UpdatedUTCDate = @DtNowUTC
			FROM Products p
			WHERE p.ProductId = @ProductId
				AND p.TenantId = @TenantId
		END

		-- Capture activity logs on product price change
		IF ISNULL(@OldCostPrice, 0) <> ISNULL(@CostPrice, 0)
		BEGIN
			INSERT INTO dbo.PriceChangeLogs (
				EntityTypeID
				,EntityID
				,OldValue
				,NewValue
				,CreatedBy
				)
			SELECT @ProductSubjectTypeId
				,@ProductId
				,@OldCostPrice
				,@CostPrice
				,@UserId

			SET @Description =  '';
			SET @Description = 'Product Cost Price has been updated from ' + CAST(ISNULL(@OldCostPrice, 0) AS VARCHAR(30)) + ' to ' + CAST(ISNULL(@CostPrice, 0) AS VARCHAR(30)) + '.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END

		IF ISNULL(@OldRetailerPrice, 0) <> ISNULL(@RetailerPrice, 0)
		BEGIN
			SET @Description =  '';
			SET @Description = 'Product Retailer Price has been updated from ' + CAST(ISNULL(@OldRetailerPrice, 0) AS VARCHAR(30)) + ' to ' + CAST(ISNULL(@RetailerPrice, 0) AS VARCHAR(30)) + '.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END

		IF ISNULL(@OldWholesalerPrice, 0) <> ISNULL(@WholesalerPrice, 0)
		BEGIN
			SET @Description =  '';
			SET @Description = 'Product Wholesaler Price has been updated from ' + CAST(ISNULL(@OldWholesalerPrice, 0) AS VARCHAR(30)) + ' to ' + CAST(ISNULL(@WholesalerPrice, 0) AS VARCHAR(30)) + '.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END

		IF ISNULL(@OldIsPriceAutoCalculated, 0) <> ISNULL(@IsPriceAutoCalculated, 0)
		BEGIN
			SET @Description =  '';
			SET @Description = 'Product Price Calculation has been changed from ' + CASE 
					WHEN @OldIsPriceAutoCalculated = 1
						THEN 'Auto'
					ELSE 'Manual'
					END + ' to ' + CASE 
					WHEN @IsPriceAutoCalculated = 1
						THEN 'Auto'
					ELSE 'Manual'
					END + '.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END

		-- Log open inquiries context
		IF @ShouldUpdateInquiries = 1
			AND @AffectedInquiriesCount > 0
		BEGIN
			SET @Description =  '';
			SET @Description = 'Product price updated. Price updated in ' + CAST(@AffectedInquiriesCount AS VARCHAR(10)) + ' open inquiries.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END
		ELSE IF @ShouldUpdateInquiries = 0
			AND @AffectedInquiriesCount > 0
		BEGIN
			SET @Description =  '';
			SET @Description = 'Product price updated. Price kept unchanged in ' + CAST(@AffectedInquiriesCount AS VARCHAR(10)) + ' open inquiries.'

			EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
				,@SubjectId = @ProductId
				,@Action = 'UPDATE'
				,@Description = @Description
				,@CreatedBy = @UserId
				,@CreatedDate = @DtNowOffset
				,@CreatedUTCDate = @DtNowUTC;
		END

		-- Populate Product Offer Price
		DECLARE @Result INT
		DECLARE @ProductIds VARCHAR(MAX) = CAST(@ProductID AS VARCHAR(MAX))

		EXEC [dbo].[UpdateProductOfferPrice] @TenantId = @TenantID
			,@CategoryId = @CategoryID
			,@ProductIds = @ProductIds
			,@Result = @Result OUTPUT

		SET @Status = 1;
		SET @Message = 'Product price updated successfully.';
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500) = OBJECT_NAME(@@PROCID)
			,@ErrorMsg VARCHAR(MAX) = ERROR_MESSAGE()
			,@ErrorSeverity INT = ERROR_SEVERITY();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SET @Status = - 2;
		SET @Message = @ErrorMsg;
	END CATCH
END

GO

