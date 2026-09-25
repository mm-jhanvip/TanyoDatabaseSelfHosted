CREATE   PROC [dbo].[SavePOProducts] (
	@POProductId BIGINT
	,@TenantId BIGINT
	,@VendorId BIGINT
	,@OrderDate DATE
	,@Status INT
	,@UserId BIGINT
	,@POProductItems NVARCHAR(MAX)
	,@ExpectedPODeliveryDate DATE
	,@OrderId BIGINT = NULL
	,@GSTType BIT
	,@CGSTAmount DECIMAL = NULL
	,@SGSTAmount DECIMAL = NULL
	,@IsInterState BIT = 0
	,@IGSTAmount NUMERIC(18, 2) = NULL
	,@OutputPOProductId BIGINT = 0 OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		DECLARE @NewPOProductId BIGINT
		DECLARE @VendorTenantId INT
			,@StatusCode BIT = 0
			,@Message VARCHAR(MAX) = ''
			,@UnPublishedProducts NVARCHAR(MAX)
			,@UnmappedProducts NVARCHAR(MAX)

		DROP TABLE IF EXISTS #POItems
		
		DROP TABLE IF EXISTS #UnmappedProducts
		
		DROP TABLE IF EXISTS #ItemMapping

		DROP TABLE IF EXISTS #OldPOItems

		DROP TABLE IF EXISTS #DeletePOItems

		DROP TABLE IF EXISTS #InsertPOItems

		DROP TABLE IF EXISTS #UpdatePOItems


		CREATE TABLE #ItemMapping (
			OldPOProductItemId BIGINT,
			NewPOProductItemId BIGINT
		)
		
		CREATE TABLE #POItems ( 
			POProductItemId BIGINT
			,ProductId BIGINT
			,VendorModelNo VARCHAR(50)
			,Quantity DECIMAL(18, 2)
			,VendorProductPrice DECIMAL(18, 2)
			,Status INT
			,Remarks NVARCHAR(500)
			,OrderSetItemId BIGINT   
			,Width DECIMAL(18, 2)    
			,Height DECIMAL(18, 2)   
			,Depth DECIMAL(18, 2)    
			,Diameter DECIMAL(18, 2)
			,GSTType BIT
			,CGSTAmount DECIMAL NULL
			,SGSTAmount DECIMAL NULL
			,GST DECIMAL NULL
		   ,IsInterState BIT NULL
		   ,IGSTAmount NUMERIC(18, 2)  NULL
			)

		SELECT *
		INTO #OldPOItems
		FROM POProductItems WITH (NOLOCK)
		WHERE POProductId = @POProductId

		INSERT INTO #POItems (
			POProductItemId
			,ProductId
			,VendorModelNo
			,Quantity
			,VendorProductPrice
			,Status
			,Remarks
			,OrderSetItemId
			,Width
			,Height
			,Depth
			,Diameter
			,GSTType
			,CGSTAmount
			,SGSTAmount
			,GST
			,[IsInterState]
			,[IGSTAmount]
			)
		SELECT POProductItemId
			,ProductId
			,VendorModelNo
			,Quantity
			,VendorProductPrice
			,Status
			,Remarks
			,OrderSetItemId
			,Width
			,Height
			,Depth
			,Diameter
			,GSTType
			,CGSTAmount
			,SGSTAmount
			,GST
			,ISNULL(IsInterState,0)
			,IGSTAmount
		FROM OPENJSON(@POProductItems) WITH (
				POProductItemId BIGINT
				,ProductId BIGINT
				,VendorModelNo VARCHAR(50)
				,Quantity DECIMAL(18, 2)
				,VendorProductPrice DECIMAL(18, 2)
				,Status INT
				,Remarks NVARCHAR(500)
				,OrderSetItemId BIGINT
				,Width DECIMAL(18, 2)
				,Height DECIMAL(18, 2)
				,Depth DECIMAL(18, 2)
				,Diameter DECIMAL(18, 2)
				,GSTType BIT
				,CGSTAmount DECIMAL
				,SGSTAmount DECIMAL
				,GST DECIMAL
				,IsInterState BIT
				,IGSTAmount NUMERIC(18, 2)
				)	

		SELECT @VendorTenantId = VendorTenantId
		FROM Vendors WITH (NOLOCK)
		WHERE VendorId = @VendorId

		IF ISNULL(@VendorTenantId, 0) > 0
		BEGIN
			CREATE TABLE #UnmappedProducts (
				DealerProductId BIGINT
				,VendorProductId BIGINT
				,ProductInfo NVARCHAR(MAX)
				,IsUnmappedProducts BIT
				)

			INSERT INTO #UnmappedProducts (
				DealerProductId
				,VendorProductId
				,ProductInfo
				,IsUnmappedProducts
				)
			SELECT pit.ProductId AS DealerProductId
				,PT.ProductId AS VendorProductId
				,CONCAT (
					'Product Tittle: '
					,PTIP.ProductTitle
					,' Product ModelNo: '
					,PTIP.ModelNo
					,' VendorModelNo: - ('
					,PVM.VendorModelNo
					,')'
					) AS ProductInfo
				,CASE 
					WHEN PVM.VendorModelNo IS NULL
						THEN 1
					ELSE 0
					END AS IsUnmappedProducts
			--INTO #UnmappedProducts
			FROM #POItems PIT
			INNER JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PIT.ProductId = PVM.ProductId
				AND PVM.VendorId = @VendorId
				AND PVM.IsDeleted = 0
			INNER JOIN Products PTIP WITH (NOLOCK) ON PTIP.ProductId = PIT.ProductId
				AND PTIP.TenantId = @TenantId
			LEFT JOIN Products PT WITH (NOLOCK) ON PT.ModelNo = PVM.VendorModelNo
				AND PT.Status <> 1
				AND PT.TenantId = @VendorTenantId

			SELECT @UnPublishedProducts = STRING_AGG(ProductInfo, ',')
			FROM #UnmappedProducts
			WHERE VendorProductId IS NOT NULL

			IF EXISTS (
					SELECT 1
					FROM #UnmappedProducts
					)
			BEGIN
				IF EXISTS (
						SELECT 1
						FROM #UnmappedProducts
						WHERE IsUnmappedProducts = 1
						)
				BEGIN
					SELECT @UnmappedProducts = STRING_AGG(ProductInfo, ',')
					FROM #UnmappedProducts
					WHERE VendorProductId IS NULL

					SET @StatusCode = 0
					SET @Message = 'These products ' + @UnmappedProducts + ' are not mapped with vendor, please contact Admin.'

					SELECT ISNULL(@POProductId, 0) AS NewPOProductId
						,@StatusCode AS StatusCode
						,@Message AS [Message]

					RETURN
				END

				IF EXISTS (
						SELECT 1
						FROM #UnmappedProducts
						WHERE VendorProductId IS NOT NULL
						)
				BEGIN
					SET @StatusCode = 0
					SET @Message = 'These products ' + @UnPublishedProducts + ' are not available, please contact to Vendor.'

					SELECT ISNULL(@POProductId, 0) AS NewPOProductId
						,@StatusCode AS StatusCode
						,@Message AS [Message]

					RETURN
				END
			END
		END

		SELECT OPIT.*
		INTO #DeletePOItems
		FROM  #OldPOItems OPIT
		LEFT JOIN #POItems PIT ON PIT.POProductItemId = OPIT.POProductItemId
		WHERE PIT.POProductItemId IS NULL

		SELECT PIT.*
		INTO #InsertPOItems
		FROM #POItems PIT
		LEFT JOIN #OldPOItems OPIT ON PIT.POProductItemId = OPIT.POProductItemId
		WHERE OPIT.POProductItemId IS NULL

		SELECT PIT.*
		INTO #UpdatePOItems
		FROM  #OldPOItems OPIT
		INNER JOIN #POItems PIT ON PIT.POProductItemId = OPIT.POProductItemId


		BEGIN TRAN SavePOProducts

		-- =========================================
		-- INSERT CASE (New PO)
		-- =========================================
		IF @POProductId = 0
		BEGIN
			DECLARE @PONumber VARCHAR(20)

			SELECT @PONumber = [dbo].[GetPONumber](@TenantId)

			UPDATE TenantConfigurations
			SET PONumberCounter = PONumberCounter + 1
			WHERE TenantId = @TenantId
				AND PONumberGenerationType = 1

			INSERT INTO [dbo].[POProducts] (
				[TenantId]
				,[VendorId]
				,[PONumber]
				,[OrderDate]
				,[Status]
				,[CreatedBy]
				,[ExpectedDeliveryDate]
				,[OrderId]
				,[GSTType]
				,[CGSTAmount]
				,[SGSTAmount]
				,[IsInterState]
				,[IGSTAmount]
				)
			VALUES (
				@TenantId
				,@VendorId
				,@PONumber
				,@OrderDate
				,@Status
				,@UserId
				,@ExpectedPODeliveryDate
				,@OrderId
				,@GSTType
				,@CGSTAmount
				,@SGSTAmount
				,@IsInterState
				,@IGSTAmount
				)

			SET @NewPOProductId = SCOPE_IDENTITY()
		END
				-- =========================================
				-- UPDATE CASE (Existing PO)
				-- =========================================
		ELSE
		BEGIN
			UPDATE dbo.POProducts
			SET OrderDate = @OrderDate
				,Status = @Status
				,UpdatedBy = @UserId
				,UpdatedDate = SYSDATETIMEOFFSET()
				,UpdatedUTCDate = GETUTCDATE()
				,ExpectedDeliveryDate = @ExpectedPODeliveryDate
				,GSTType = @GSTType
				,CGSTAmount = @CGSTAmount
				,SGSTAmount = @SGSTAmount
				,IsInterState = @IsInterState
				,IGSTAmount = @IGSTAmount
			WHERE POProductId = @POProductId

			SET @NewPOProductId = @POProductId

			-- Optionally delete old items before re-inserting
			--DELETE
			--FROM dbo.POProductItems
			--WHERE POProductId = @NewPOProductId
		END
				-- =========================================
				-- INSERT ITEMS
				-- =========================================
				;

		--WITH POItems
		--AS (
		--	SELECT ProductId
		--		,VendorModelNo
		--		,Quantity
		--		,VendorProductPrice
		--		,ExpectedDeliveryDate
		--		,Status
		--		,Remarks
		--	FROM OPENJSON(@POProductItems) WITH (
		--			ProductId BIGINT
		--			,VendorModelNo VARCHAR(50)
		--			,Quantity DECIMAL(18, 2)
		--			,VendorProductPrice DECIMAL(18, 2)
		--			,ExpectedDeliveryDate DATE
		--			,Status INT
		--			,Remarks NVARCHAR(500)
		--			)
		--	)

		IF EXISTS (SELECT 1 FROM #DeletePOItems)
		BEGIN

			DELETE PIT
			FROM POProductItems PIT
			INNER JOIN #DeletePOItems DPIT ON PIT.POProductItemId = DPIT.POProductItemId

			DELETE PAIT
			FROM POProductItemsAttachments PAIT
			INNER JOIN #DeletePOItems DPIT ON PAIT.POProductItemId = DPIT.POProductItemId

		
		END

		IF EXISTS (SELECT 1 FROM #UpdatePOItems)
		BEGIN

			UPDATE PIT
			SET Quantity = UPIT.Quantity
			,UnitPrice = UPIT.VendorProductPrice
			--,Status = UPIT.Status
			,Remarks = UPIT.Remarks
			--,OrderSetItemId = UPIT.OrderSetItemId
			,Width = UPIT.Width
			,Height = UPIT.Height
			,Depth = UPIT.Depth
			,Diameter = UPIT.Diameter
			,GSTType = UPIT.GSTType
			,CGSTAmount = UPIT.CGSTAmount
			,SGSTAmount = UPIT.SGSTAmount
			,GST = UPIT.GST
			,IsInterState = UPIT.IsInterState
			,IGSTAmount = UPIT.IGSTAmount
			FROM POProductItems PIT 
			INNER JOIN #UpdatePOItems UPIT ON PIT.POProductItemId = UPIT.POProductItemId
		END


		IF EXISTS ( SELECT 1 FROM #InsertPOItems )
		BEGIN
			INSERT INTO dbo.POProductItems (
				POProductId
				,ProductId
				,VendorModelNo
				,Quantity
				,UnitPrice
				,Status
				,Remarks
				,CreatedBy
				,OrderSetItemId
				,Width
				,Height
				,Depth
				,Diameter
				,GSTType
				,CGSTAmount
				,SGSTAmount
				,GST
				,[IsInterState]
				,[IGSTAmount]
				)
			SELECT @NewPOProductId
				,ProductId
				,VendorModelNo
				,Quantity
				,VendorProductPrice
				,Status
				,Remarks
				,@UserId
				,OrderSetItemId
				,Width
				,Height
				,Depth
				,Diameter
				,GSTType
				,CGSTAmount
				,SGSTAmount
				,GST
				,[IsInterState]
				,[IGSTAmount]
			FROM #InsertPOItems 
		END
		DECLARE @TotalAmount DECIMAL(18, 2)
		DECLARE @AmountBeforeGST DECIMAL(18, 2)

		--SELECT @TotalAmount = SUM(TotalPrice)
		--FROM dbo.POProductItems poi
		--WHERE poi.POProductId = @NewPOProductId

		SELECT @TotalAmount = SUM(TotalAmount)
				,@AmountBeforeGST = SUM(AmountBeforeGST)
		FROM dbo.POProductItems poi
		WHERE poi.POProductId = @NewPOProductId

		UPDATE dbo.POProducts
		SET TotalAmount = @TotalAmount
			,AmountBeforeGST = @AmountBeforeGST
		WHERE POProductId = @NewPOProductId

		COMMIT TRAN SavePOProducts

		SET @OutputPOProductId = @NewPOProductId;
		SET @StatusCode = 1;
		SET @Message = CASE 
				WHEN ISNULL(@POProductId, 0) > 0
					THEN 'PO updated successfully.'
				ELSE 'PO generated successfully.'
				END;

		SELECT @NewPOProductId AS NewPOProductId -- Return final ID
			,@StatusCode AS StatusCode
			,@Message AS [Message]
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SavePOProducts

		DECLARE @ObjectName VARCHAR(500)
		,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

