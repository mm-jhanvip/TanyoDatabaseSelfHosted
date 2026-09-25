CREATE PROCEDURE [dbo].[UpdateImportProducts] (
	@WrkProductID BIGINT
	,@UserId INT
	,@TotalRecords INT
	,@ProcessStartDate DATETIMEOFFSET = NULL
	,@ProcessEndDate DATETIMEOFFSET = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN UpdateImportProducts

		DROP TABLE IF EXISTS #VendorList

		DROP TABLE IF EXISTS #ExistingVendorList

		DROP TABLE IF EXISTS #UnmappedVendors

		DROP TABLE IF EXISTS #TempResponse

			DECLARE @TenantId BIGINT
				,@WrkImportFileID BIGINT
				,@CategoryName VARCHAR(MAX)
				,@ProductTitle VARCHAR(MAX)
				,@ModelNo VARCHAR(MAX)
				,@VendorName VARCHAR(MAX)
				,@UnMappedVendorName VARCHAR(MAX)
				,@MergedVendorNames VARCHAR(MAX)
				,@NewVendorList VARCHAR(MAX)
				,@CountVendorList INT
				,@CountUnmappedVendors INT
				,@CostPrice VARCHAR(MAX)
				,@RetailerPrice VARCHAR(MAX)
				,@WholesalerPrice VARCHAR(MAX)
				,@Width VARCHAR(MAX)
				,@Height VARCHAR(MAX)
				,@Depth VARCHAR(MAX)
				,@Diameter VARCHAR(MAX)
				,@StockQty VARCHAR(MAX)
				,@CategoryId INT
				,@ProductId BIGINT
				,@TenantLogo VARCHAR(800)
				,@ErrorMessage VARCHAR(MAX) = ''
				,@dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
				,@dtUTC DATETIME = GETUTCDATE()
				,@MaxDimension NUMERIC(18, 2) = 9999.99
				,@TempDecimal NUMERIC(18, 2)
				,@SetDefault BIT = 0
				,@RetailTempDecimal NUMERIC(18, 2)
				,@WholesalerTempDecimal NUMERIC(18, 2)
				,@CategoryTypeId BIGINT
				,@OldWidth NUMERIC(18, 2)
				,@OldHeight NUMERIC(18, 2)
				,@OldDepth NUMERIC(18, 2)
				,@OldDiameter NUMERIC(18, 2)
				,@OldCostPrice NUMERIC(18, 2)
				,@OldRetailerPrice NUMERIC(18, 2)
				,@OldWholesalerPrice NUMERIC(18, 2)
				,@ProductSubjectType INT
				,@IsPriceAutoCalculated BIT
				,@LogDescription VARCHAR(MAX);

		SELECT @TenantId = WIF.TenantId
			,@WrkImportFileID = WP.WrkImportFileID
			,@CategoryName = WP.CategoryName
			,@ProductTitle = WP.ProductTitle
			,@ModelNo = WP.ModelNo
			,@VendorName = WP.VendorName
			,@CostPrice = WP.CostPrice
			,@RetailerPrice = WP.RetailerPrice
			,@WholesalerPrice = WP.WholesalerPrice
			,@Width = WP.Width
			,@Height = WP.Height
			,@Depth = WP.Depth
			,@Diameter = WP.Diameter
			,@StockQty = WP.StockQty
		FROM WrkProducts WP WITH (NOLOCK)
		INNER JOIN WrkImportFiles WIF ON WP.WrkImportFileID = WIF.WrkImportFileID
		WHERE WP.WrkProductID = @WrkProductID

		SELECT @TenantLogo = LogoPath
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId

		SELECT @ProductSubjectType = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId

		SELECT @CategoryId = CategoryId
			,@CategoryTypeId = CategoryTypeId
		FROM Categories WITH (NOLOCK)
		WHERE LOWER(CategoryName) = LOWER(TRIM(@CategoryName))
			AND TenantId = @TenantId
			AND IsDeleted = 0

		IF @CategoryId IS NULL
			SET @ErrorMessage += 'Category does not exist. '

		IF ISNULL(@ProductTitle, '') = ''
			SET @ErrorMessage += 'Product Title is required. '

		IF ISNULL(@ModelNo, '') = ''
			SET @ErrorMessage += 'ModelNo is required. '

		IF CHARINDEX(' ', @ModelNo) > 0
			SET @ErrorMessage += 'ModelNo does not allow spaces. '

		IF LEN(@ModelNo) > 100
			SET @ErrorMessage += 'ModelNo max length is 100. '

		IF PATINDEX('%[^a-zA-Z0-9/_-]%', @ModelNo) > 0
			SET @ErrorMessage += 'Invalid ModelNo format. '

		SELECT @ProductId = ProductId
			,@OldWidth = Width
			,@OldHeight = Height
			,@OldDepth = Depth
			,@OldDiameter = Diameter
			,@OldCostPrice = CostPrice
			,@OldRetailerPrice = RetailerPrice
			,@OldWholesalerPrice = WholesalerPrice
		FROM Products WITH (NOLOCK)
		WHERE CategoryId = @CategoryId
			AND LOWER(ProductTitle) = LOWER(@ProductTitle)
			AND LOWER(ModelNo) = LOWER(@ModelNo)
			AND TenantId = @TenantId
			AND Status <> 3

		IF @ProductId IS NULL
		BEGIN
			SET @ErrorMessage += 'Product not found for update. '
		END

		IF ISNULL(@Width, '') <> ''
		BEGIN
			SET @TempDecimal = TRY_CAST(@Width AS DECIMAL(18, 2))

			IF @TempDecimal IS NULL
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Width allows only numeric values. '
			ELSE IF @TempDecimal > @MaxDimension
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Width exceeds the limit of 9999.99. '
		END

		IF ISNULL(@Height, '') <> ''
		BEGIN
			SET @TempDecimal = TRY_CAST(@Height AS DECIMAL(18, 2))

			IF @TempDecimal IS NULL
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Height allows only numeric values. '
			ELSE IF @TempDecimal > @MaxDimension
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Height exceeds the limit of 9999.99. '
		END

		IF ISNULL(@Depth, '') <> ''
		BEGIN
			SET @TempDecimal = TRY_CAST(@Depth AS DECIMAL(18, 2))

			IF @TempDecimal IS NULL
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Depth allows only numeric values. '
			ELSE IF @TempDecimal > @MaxDimension
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Depth exceeds the limit of 9999.99. '
		END

		IF ISNULL(@Diameter, '') <> ''
		BEGIN
			SET @TempDecimal = TRY_CAST(@Diameter AS DECIMAL(18, 2))

			IF @TempDecimal IS NULL
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Diameter allows only numeric values. '
			ELSE IF @TempDecimal > @MaxDimension
				SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Diameter exceeds the limit of 9999.99. '
		END

		IF ISNULL(@CostPrice, '') <> ''
		BEGIN
			SET @TempDecimal = TRY_CAST(@CostPrice AS NUMERIC(18, 2))

			IF @TempDecimal IS NULL
				SET @ErrorMessage += 'Cost Price invalid. '
			ELSE IF @TempDecimal < 0
				SET @ErrorMessage += 'Cost Price cannot be negative. '
		END

		IF ISNULL(@RetailerPrice, '') <> ''
		BEGIN
			SET @RetailTempDecimal = TRY_CAST(@RetailerPrice AS NUMERIC(18, 2))

			IF @RetailTempDecimal IS NULL
				SET @ErrorMessage += 'Retailer Price invalid. '
			ELSE IF @RetailTempDecimal < 0
				SET @ErrorMessage += 'Retailer Price cannot be negative. '
		END

		IF ISNULL(@WholesalerPrice, '') <> ''
		BEGIN
			SET @WholesalerTempDecimal = TRY_CAST(@WholesalerPrice AS NUMERIC(18, 2))

			IF @WholesalerTempDecimal IS NULL
				SET @ErrorMessage += 'Wholesaler Price invalid. '
			ELSE IF @WholesalerTempDecimal < 0
				SET @ErrorMessage += 'Wholesaler Price cannot be negative. '
		END

		SELECT NULL AS VendorId
			,TRIM(value) AS VendorName
		INTO #VendorList
		FROM STRING_SPLIT(@VendorName, ',')

		IF ISNULL(@VendorName, '') <> ''
		BEGIN
			SELECT V.VendorName
			INTO #UnMappedVendorName
			FROM #VendorList V
			WHERE NOT EXISTS (
					SELECT 1
					FROM Vendors VD WITH (NOLOCK)
					WHERE LOWER(VD.VendorName) = LOWER(LTRIM(RTRIM(V.VendorName)))
						AND VD.TenantId = @TenantId
					)

			IF EXISTS (
					SELECT 1
					FROM #UnMappedVendorName
					)
			BEGIN
				SELECT @UnMappedVendorName = STRING_AGG(V.VendorName, ',')
				FROM #UnMappedVendorName V

				SET @ErrorMessage = @ErrorMessage + @UnMappedVendorName + ' Vendor does not exist. '
			END

			IF EXISTS (
					SELECT 1
					FROM #VendorList
					WHERE PATINDEX('%[^A-Za-z0-9&./()'' -]%', VendorName) > 0
					)
			BEGIN
				SET @ErrorMessage = @ErrorMessage + 'Vendor name contains invalid characters. ';
			END
		END

		IF ISNULL(@CategoryTypeId, 0) <> 1
		BEGIN
			SET @ErrorMessage = ISNULL(@ErrorMessage, '') + 'Only product records can be processed using this module. Please use the appropriate module for fabric. '
		END

		IF @ErrorMessage = ''
		BEGIN
			IF NOT EXISTS (
					SELECT 1
					FROM ProductVendorMapping
					WHERE ProductId = @ProductId
						AND IsDeleted = 0
						AND IsDefault = 1
					)
			BEGIN
				SET @SetDefault = 1
			END

			SELECT @MergedVendorNames = isnull(VendorNames, '')
			FROM Products WITH (NOLOCK)
			WHERE ProductId = @ProductId

			SELECT TRIM(value) AS VendorName
			INTO #ExistingVendorList
			FROM STRING_SPLIT(@MergedVendorNames, ',')

			SELECT @NewVendorList = STRING_AGG(VendorName, ',')
			FROM #VendorList
			WHERE VendorName NOT IN (
					SELECT VendorName
					FROM #ExistingVendorList
					)

			SET @MergedVendorNames = @MergedVendorNames + IIF(ISNULL(@NewVendorList, '') <> ''
					AND ISNULL(@MergedVendorNames, '') <> '', ',' + ISNULL(@NewVendorList, ''), ISNULL(@NewVendorList, ''))

			UPDATE VL
			SET VL.VendorId = V.VendorId
			FROM #VendorList VL
			INNER JOIN Vendors V ON V.VendorName = VL.VendorName
				AND V.TenantId = @TenantId

			SELECT VendorId
				,VendorName
				,0 AS IsDefault
			INTO #UnmappedVendors
			FROM #VendorList VL
			WHERE NOT EXISTS (
					SELECT 1
					FROM ProductVendorMapping PVM WITH (NOLOCK)
					WHERE VL.VendorId = PVM.VendorId
						AND PVM.ProductId = @ProductId
					)

			SELECT @CountVendorList = COUNT(VendorId)
			FROM #VendorList

			SELECT @CountUnmappedVendors = COUNT(VendorId)
			FROM #UnmappedVendors

			IF @SetDefault = 1
				AND ISNULL(@CountVendorList, 0) > 0
			BEGIN
				UPDATE UV
				SET IsDefault = 1
				FROM #UnmappedVendors UV
				WHERE UV.VendorId IN (
						SELECT TOP 1 VendorId
						FROM #UnmappedVendors
						ORDER BY VendorId
						)
			END

			UPDATE Products
			SET Width = CASE 
					WHEN @Width IS NULL
						OR @Width = ''
						THEN Width
					WHEN CAST(NULLIF(@Width, '') AS NUMERIC(18, 2)) = 0
						THEN 1
					ELSE CAST(@Width AS NUMERIC(18, 2))
					END
				,Height = CASE 
					WHEN @Height IS NULL
						OR @Height = ''
						THEN Height
					WHEN CAST(NULLIF(@Height, '') AS NUMERIC(18, 2)) = 0
						THEN 1
					ELSE CAST(@Height AS NUMERIC(18, 2))
					END
				,Depth = CASE 
					WHEN @Depth IS NULL
						OR @Depth = ''
						THEN Depth
					WHEN CAST(NULLIF(@Depth, '') AS NUMERIC(18, 2)) = 0
						THEN 1
					ELSE CAST(@Depth AS NUMERIC(18, 2))
					END
				,Diameter = CASE 
					WHEN @Diameter IS NULL
						OR @Diameter = ''
						THEN Diameter
					WHEN CAST(NULLIF(@Diameter, '') AS NUMERIC(18, 2)) = 0
						THEN 1
					ELSE CAST(@Diameter AS NUMERIC(18, 2))
					END
				--,CostPrice = CASE 
				--	WHEN @CostPrice IS NULL OR @CostPrice = ''
				--		THEN CostPrice
				--	ELSE CAST(@CostPrice AS NUMERIC(18, 2))
				--	END
				--,RetailerPrice = CASE 
				--	WHEN @RetailerPrice IS NULL OR @RetailerPrice = ''
				--		THEN RetailerPrice
				--	ELSE CAST(@RetailerPrice AS NUMERIC(18, 2))
				--	END
				--,WholesalerPrice = CASE 
				--	WHEN @WholesalerPrice IS NULL OR @WholesalerPrice = ''
				--		THEN WholesalerPrice
				--	ELSE CAST(@WholesalerPrice AS NUMERIC(18, 2))
				--	END
				--,IsPriceAutoCalculated = CASE 
				--	WHEN (@CostPrice IS NOT NULL AND @CostPrice <> '')
				--		AND (@RetailerPrice IS NULL OR @RetailerPrice = '' )
				--		AND (@WholesalerPrice IS NULL OR @WholesalerPrice = '')
				--		THEN 1
				--	ELSE 0
				--	END
				,VendorNames = @MergedVendorNames
				,UpdatedBy = @UserId
				,UpdatedDate = @dt
				,UpdatedUTCDate = @dtUTC
			WHERE ProductId = @ProductId

			SET @IsPriceAutoCalculated = 0
			SET @IsPriceAutoCalculated = CASE 
					WHEN (
							@CostPrice IS NOT NULL
							AND @CostPrice <> ''
							)
						AND (
							@RetailerPrice IS NULL
							OR @RetailerPrice = ''
							)
						AND (
							@WholesalerPrice IS NULL
							OR @WholesalerPrice = ''
							)
						THEN 1
					ELSE 0
					END

			SELECT @CostPrice = CASE 
					WHEN @CostPrice IS NULL
						OR @CostPrice = ''
						THEN CostPrice
					ELSE CAST(@CostPrice AS NUMERIC(18, 2))
					END
				,@RetailerPrice = CASE 
					WHEN @RetailerPrice IS NULL
						OR @RetailerPrice = ''
						THEN RetailerPrice
					ELSE CAST(@RetailerPrice AS NUMERIC(18, 2))
					END
				,@WholesalerPrice = CASE 
					WHEN @WholesalerPrice IS NULL
						OR @WholesalerPrice = ''
						THEN WholesalerPrice
					ELSE CAST(@WholesalerPrice AS NUMERIC(18, 2))
					END
			FROM Products p WITH (NOLOCK)
			WHERE p.ProductId = @ProductId

			DECLARE @Status INT
				,@Message VARCHAR(500)

			EXEC dbo.PopulateProductPriceById @ProductId = @ProductId
				,@UserId = @UserId
				,@TenantId = @TenantId
				,@CostPrice = @CostPrice
				,@RetailerPrice = @RetailerPrice
				,@WholesalerPrice = @WholesalerPrice
				,@IsPriceAutoCalculated = @IsPriceAutoCalculated
				,@Status = @Status OUTPUT
				,@Message = @Message OUTPUT

			---------------------------------------------------------
			-- APPLY OFFER PRICE LOGIC (IMPORTANT FIX)
			---------------------------------------------------------
			DECLARE @Today DATE = GETDATE();

			-- If NO active offer → reset prices
			UPDATE p
			SET p.RetailOfferPrice = NULL
				,p.WholesalerOfferPrice = NULL
			FROM Products p
			WHERE p.ProductId = @ProductId
				AND NOT EXISTS (
					SELECT 1
					FROM OfferProductMapping opm
					INNER JOIN Offers o ON o.OfferId = opm.OfferId
					WHERE opm.ProductId = p.ProductId
						AND o.StartDate <= @Today
						AND o.EndDate >= @Today
						AND o.IsPublished = 1
					);

			-- If ACTIVE offer → recalculate
			UPDATE p
			SET p.RetailOfferPrice = ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2)
				,p.WholesalerOfferPrice = ROUND((p.WholesalerPrice - ((p.WholesalerPrice * o.OfferPercentage) / 100)), 2)
			FROM Products p
			INNER JOIN OfferProductMapping opm ON opm.ProductId = p.ProductId
			INNER JOIN Offers o ON o.OfferId = opm.OfferId
			WHERE p.ProductId = @ProductId
				AND o.StartDate <= @Today
				AND o.EndDate >= @Today
				AND o.IsPublished = 1
				AND (
					ISNULL(p.RetailOfferPrice, 0) <> ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2)
					OR ISNULL(p.WholesalerOfferPrice, 0) <> ROUND((p.WholesalerPrice - ((p.WholesalerPrice * o.OfferPercentage) / 100)), 2)
					);

			IF ISNULL(@CountUnmappedVendors, 0) > 0
			BEGIN
				INSERT INTO ProductVendorMapping (
					ProductId
					,VendorId
					,IsDefault
					,CreatedBy
					,CreatedDate
					,CreatedUTCDate
					)
				SELECT @ProductId
					,VendorId
					,IsDefault
					,@UserId
					,@dt
					,@dtUTC
				FROM #UnmappedVendors
			END

			UPDATE WrkProducts
			SET Status = 2
				,ErrorMessage = NULL
			WHERE WrkProductID = @WrkProductID

			IF ISNULL(@ProductId, 0) > 0
				AND (
					@CostPrice IS NOT NULL
					AND @CostPrice <> ''
					)
				AND (
					@RetailerPrice IS NULL
					OR @RetailerPrice = ''
					)
				AND (
					@WholesalerPrice IS NULL
					OR @WholesalerPrice = ''
					)
			BEGIN
				CREATE TABLE #TempResponse (
					Status BIT
					,Message VARCHAR(128)
					,Data VARCHAR(2056)
					,Error VARCHAR(2056)
					)

				INSERT INTO #TempResponse
				EXEC UpdateProductPriceByCategory @TenantID = @TenantID
					,@CategoryID = @CategoryID
					,@ProductID = @ProductId
			END

			IF ISNULL(@Width, '') <> ''
				AND @OldWidth <> CAST(@Width AS NUMERIC(18, 2))
			BEGIN
			    SET @LogDescription = ''
				SET @LogDescription = 'Width changed from ' + CAST(@OldWidth AS VARCHAR(32)) + ' to ' + CASE 
						WHEN CAST(NULLIF(@Width, '') AS NUMERIC(18, 2)) = 0
							THEN '1'
						ELSE @Width
						END + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@Height, '') <> ''
				AND @OldHeight <> CAST(@Height AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Height changed from ' + CAST(@OldHeight AS VARCHAR(32)) + ' to ' + CASE 
						WHEN CAST(NULLIF(@Height, '') AS NUMERIC(18, 2)) = 0
							THEN '1'
						ELSE @Height
						END + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@Depth, '') <> ''
				AND @OldDepth <> CAST(@Depth AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Depth changed from ' + CAST(@OldDepth AS VARCHAR(32)) + ' to ' + CASE 
						WHEN CAST(NULLIF(@Depth, '') AS NUMERIC(18, 2)) = 0
							THEN '1'
						ELSE @Depth
						END + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@Diameter, '') <> ''
				AND @OldDiameter <> CAST(@Diameter AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Diameter changed from ' + CAST(@OldDiameter AS VARCHAR(32)) + ' to ' + CASE 
						WHEN CAST(NULLIF(@Diameter, '') AS NUMERIC(18, 2)) = 0
							THEN '1'
						ELSE @Diameter
						END + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@CostPrice, '') <> ''
				AND @OldCostPrice <> CAST(@CostPrice AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Cost price changed from ' + CAST(@OldCostPrice AS VARCHAR(32)) + ' to ' + @CostPrice + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@RetailerPrice, '') <> ''
				AND @OldRetailerPrice <> CAST(@RetailerPrice AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Retailer price changed from ' + CAST(@OldRetailerPrice AS VARCHAR(32)) + ' to ' + @RetailerPrice + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@WholesalerPrice, '') <> ''
				AND @OldWholesalerPrice <> CAST(@WholesalerPrice AS NUMERIC(18, 2))
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Wholesaler price changed from ' + CAST(@OldWholesalerPrice AS VARCHAR(32)) + ' to ' + @WholesalerPrice + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END

			IF ISNULL(@NewVendorList, '') <> ''
			BEGIN
				SET @LogDescription = ''
				SET @LogDescription = 'Vendor Names changed from ' + ISNULL(@MergedVendorNames, '') + ' to ' + @NewVendorList + ' by import file.'

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectType
					,@SubjectId = @ProductId
					,@Description = @LogDescription
					,@Action = 'UPDATE'
					,@CreatedBy = @UserId
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;
			END
		END
		ELSE
		BEGIN
			UPDATE WrkProducts
			SET Status = 3
				,ErrorMessage = @ErrorMessage
			WHERE WrkProductID = @WrkProductID
		END

		UPDATE WrkImportFiles
		SET Success = CASE 
				WHEN @ErrorMessage = ''
					THEN ISNULL(Success, 0) + 1
				ELSE ISNULL(Success, 0)
				END
			,Failed = CASE 
				WHEN @ErrorMessage <> ''
					THEN ISNULL(Failed, 0) + 1
				ELSE ISNULL(Failed, 0)
				END
			,Status = 2
			,TotalRecords = @TotalRecords
			,ProcessStartDate = CASE 
				WHEN @ProcessStartDate IS NULL
					THEN ProcessStartDate
				ELSE @ProcessStartDate
				END
			,ProcessEndDate = CASE 
				WHEN @ProcessEndDate IS NULL
					THEN ProcessEndDate
				ELSE @ProcessEndDate
				END
			,UpdatedBy = @UserId
			,UpdatedDate = @dt
			,UpdatedUTCDate = @dtUTC
		WHERE WrkImportFileID = @WrkImportFileID;

		--Return Result
		SELECT @ProductId AS ProductId
			,@TenantId AS TenantId
			,CASE 
				WHEN @ErrorMessage = ''
					THEN @TenantLogo
				ELSE NULL
				END AS TenantLogo
			,NULLIF(@ErrorMessage, '') AS ErrorMessage

		IF @ErrorMessage = ''
		BEGIN
			-- Get all open inquiries for the product
			DECLARE @OpenInquiries TABLE (
				Id INT IDENTITY(1, 1)
				,OrderId BIGINT
				)

			INSERT INTO @OpenInquiries (OrderId)
			EXEC [dbo].[GetOpenInquiriesByProductId] @TenantId = @TenantId
				,@ProductId = @ProductId

			-- Refresh inquiry for each affected order
			DECLARE @OrderId BIGINT
				,@cnt INT
				,@inc INT = 1

			SELECT @cnt = COUNT(*)
			FROM @OpenInquiries

			WHILE @cnt >= @inc
			BEGIN
				SET @OrderId = NULL

				SELECT @OrderId = OrderId
				FROM @OpenInquiries
				WHERE Id = @inc

				EXEC dbo.UpdateOrderRefreshInquiry @OrderId = @OrderId
					,@TenantId = @TenantId
					,@UserId = @UserId

				SET @inc = @inc + 1
			END
		END

		COMMIT TRAN UpdateImportProducts
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN UpdateImportProducts;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMessages NVARCHAR(4000)
			,@ErrorSeverity INT
			,@ErrorState INT

		SELECT @ErrorMessages = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		SET @ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessages

		SELECT NULL AS ProductId
			,@TenantId AS TenantId
			,NULL AS TenantLogo
			,@ErrorMessages AS ErrorMessage
	END CATCH
END

GO

