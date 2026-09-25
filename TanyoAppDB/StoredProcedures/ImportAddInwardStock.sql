/*
EXEC [ImportAddInwardStock]
	@WrkInwardProductID  = 1
	,@UserId  = 4689
	,@TotalRecords  = 1
	,@ProcessStartDate  = NULL
	,@ProcessEndDate  = NULL

*/

CREATE PROCEDURE [dbo].[ImportAddInwardStock] (
	@WrkInwardProductID BIGINT
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
		BEGIN TRAN;

		DECLARE @TenantId BIGINT
			,@WrkImportFileID BIGINT
			,@CategoryName VARCHAR(MAX)
			,@ProductTitle VARCHAR(MAX)
			,@ModelNo VARCHAR(MAX)
			,@WarehouseName VARCHAR(MAX)
			,@StockQty VARCHAR(MAX)
			,@CategoryId INT
			,@ProductId BIGINT
			,@WarehouseId BIGINT
			,@OtherWarehouseId BIGINT
			,@TenantLogo VARCHAR(800)
			,@ErrorMessage VARCHAR(MAX) = ''
			,@dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@dtUTC DATETIME = GETUTCDATE()
			,@StockQtyNumeric NUMERIC(18,2)
			,@CategoryTypeId BIGINT
			,@VendorName VARCHAR (MAX)
			,@VendorId	BIGINT
			,@InwardNumber VARCHAR(16)
			,@InwardId	BIGINT;

			DECLARE @OldQty NUMERIC(18,2) = 0
			,@ProductQty NUMERIC(18,2) = 0
			,@OldProductQty NUMERIC(18,2);

			DECLARE @TotalQty NUMERIC(18,2);

		SELECT @TenantId = WIF.TenantId
			,@WrkImportFileID = WP.WrkImportFileID
			,@CategoryName = TRIM(WP.CategoryName)
			,@ProductTitle = TRIM(WP.ProductTitle)
			,@ModelNo = TRIM(WP.ModelNo)
			,@WarehouseName = TRIM(WP.WarehouseName)
			,@StockQty = TRIM(WP.StockQty)
			,@VendorName = TRIM(WP.VendorName)
		FROM WrkInwardProducts WP WITH (NOLOCK)
		INNER JOIN WrkImportFiles WIF ON WP.WrkImportFileID = WIF.WrkImportFileID
		WHERE WP.WrkInwardProductID = @WrkInwardProductID;

		SELECT @TenantLogo = LogoPath
		FROM Tenants WITH (NOLOCK)
		WHERE TenantId = @TenantId


		SELECT @CategoryId = CategoryId
		,@CategoryTypeId = CategoryTypeId
		FROM Categories WITH (NOLOCK)
		WHERE LOWER(CategoryName) = LOWER(@CategoryName)
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		IF @CategoryName IS NULL
			OR @CategoryName = ''
			SET @ErrorMessage += 'Category is required. ';
		ELSE IF @CategoryId IS NULL
			SET @ErrorMessage += 'Category does not exist. ';


		IF ISNULL(@WarehouseName, '') <> ''
		BEGIN
			SELECT @WarehouseId = Id
			FROM Warehouse WITH (NOLOCK)
			WHERE LOWER(Name) = LOWER(@WarehouseName)
			AND TenantId = @TenantId;

			IF @WarehouseId IS NULL
				SET @ErrorMessage += 'Requested warehouse record does not exist. ';
		END
		ELSE
			SET @WarehouseId = 0;

		IF ISNULL(@ProductTitle, '') = ''
			SET @ErrorMessage += 'Product Title is required. ';


		IF ISNULL(@ModelNo, '') = ''
			SET @ErrorMessage += 'ModelNo is required. ';
		ELSE
		BEGIN
			IF CHARINDEX(' ', @ModelNo) > 0
				SET @ErrorMessage += 'ModelNo does not allow white space. ';

			IF LEN(@ModelNo) > 100
				SET @ErrorMessage += 'Maximum length of ModelNo is 100 characters. ';

			IF PATINDEX('%[^a-zA-Z0-9/_-]%', @ModelNo) > 0
				SET @ErrorMessage += 'ModelNo does not allow special characters. ';
					
		END


		SET @StockQtyNumeric = TRY_CAST(@StockQty AS NUMERIC(18,2));

		IF @StockQty IS NULL
			OR @StockQty = ''
			OR @StockQtyNumeric IS NULL
			OR @StockQtyNumeric <= 0
			SET @ErrorMessage += 'Current Stock must be a valid (non-negative,non zero) number. ';

		SELECT @ProductId = ProductId
		FROM Products WITH (NOLOCK)
		WHERE CategoryId = @CategoryId
			AND LOWER(ProductTitle) = LOWER(@ProductTitle)
			AND LOWER(ModelNo) = LOWER(@ModelNo)
			AND TenantId = @TenantId
			AND STATUS <> 3;

		IF @ProductId IS NULL
			SET @ErrorMessage += IIF(@CategoryTypeId = 2,'Fabric','Product') + ' not found with given details. ';

		--IF ISNULL(@VendorName, '') = ''
		--    SET @ErrorMessage += 'Vendor name is required. ';
		--ELSE
		IF ISNULL(@VendorName, '') <> ''
		BEGIN
		    SELECT @VendorId = VendorId
		    FROM Vendors
		    WHERE LOWER(VendorName) = LOWER(@VendorName)
		    AND TenantId = @TenantId;
		
		    IF @VendorId IS NULL
		        SET @ErrorMessage += 'Vendor not found with given details. ';
		END

		IF ISNULL(@ProductId,0) > 0  
			AND ISNULL(@VendorId,0) > 0
			AND NOT EXISTS 
			(
				SELECT 1
				FROM ProductVendorMapping PVM WITH (NOLOCK)
				WHERE PVM.ProductId = @ProductId
				AND PVM.VendorId = @VendorId
				AND PVM.IsDeleted = 0
			)
		BEGIN

			SET @ErrorMessage += 'Vendor not mapped with given Product: ' + @ProductTitle + ' ( ' + @ModelNo + ') ';


		END


		IF @ErrorMessage = ''
		BEGIN
			SELECT @OtherWarehouseId = Id
			FROM Warehouse WITH (NOLOCK)
			WHERE Name = 'Other'
			AND TenantId = @TenantId;

			IF @WarehouseId = 0
				SET @WarehouseId = @OtherWarehouseId;


			SELECT @OldProductQty = Quantity
			from ProductQuantities WITH (NOLOCK)
			where ProductId = @ProductId

			SELECT @OldQty = Quantity
			FROM ProductQuantitiesByWarehouse WITH (NOLOCK)
			WHERE ProductId = @ProductId
				AND WarehouseId = @WarehouseId;

			IF EXISTS (
					SELECT 1
					FROM ProductQuantitiesByWarehouse WITH (NOLOCK)
					WHERE ProductId = @ProductId
						AND WarehouseId = @WarehouseId
					)
			BEGIN
				UPDATE PQBW
				SET Quantity = Quantity + @StockQtyNumeric
					,QuantityDate = CAST(@dt AS DATE)
					,LastModifiedBy = @UserId
					,LastModifiedDate = @dt
					,LastModifiedUTCDate = @dtUTC
					FROM ProductQuantitiesByWarehouse PQBW
				WHERE ProductId = @ProductId
					AND WarehouseId = @WarehouseId;
			END
			ELSE
			BEGIN
				INSERT INTO ProductQuantitiesByWarehouse (
					ProductId
					,WarehouseId
					,Quantity
					,QuantityDate
					,LastModifiedBy
					,LastModifiedDate
					,LastModifiedUTCDate
					)
				VALUES (
					@ProductId
					,@WarehouseId
					,@StockQtyNumeric
					,CAST(@dt AS DATE)
					,@UserId
					,@dt
					,@dtUTC
					);
			END

			SELECT @TotalQty = SUM(Quantity)
			FROM ProductQuantitiesByWarehouse WITH (NOLOCK)
			WHERE ProductId = @ProductId;

			UPDATE PQ
			SET Quantity = Quantity + @StockQtyNumeric
				,QuantityDate =@dt
				,LastModifiedBy = @UserId
				,LastModifiedDate = @dt
				,LastModifiedUTCDate = @dtUTC
			FROM ProductQuantities PQ
			WHERE ProductId = @ProductId;

			SELECT @InwardNumber = dbo.GetInwardKey('IN')

			INSERT INTO InwardEntry
			(
			   VendorId
			   ,TenantId
			   ,InwardEntryNumber
			   ,IsDeleted
			   ,CreatedBy
			   ,CreatedDate
			   ,CreatedUTCDate
			   ,InwardType
				,CustomerId
			)
			SELECT 
			ISNULL(@VendorId,0)
			,@TenantId
			,@InwardNumber
			,0
			,@UserId
			,@dt
			,@dtutc
			,1
			,0

			SELECT @InwardId = SCOPE_IDENTITY()

			INSERT INTO InwardDetailsEntry (
				ProductId
				,Amount
				,Quantity
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				,WarehouseId
				,IsDeleted
				,InwardId
				)
			SELECT P.ProductId
				,P.CostPrice
				,@StockQtyNumeric
				,@UserId
				,@dt
				,@dtUTC
				,CASE 
					WHEN @WarehouseId > 0
						THEN @WarehouseId
					ELSE NULL
					END
				,0
				,@InwardId
			FROM Products P WITH (NOLOCK)
			WHERE P.ProductId = @ProductId;

			SELECT @ProductQty = Quantity
			FROM ProductQuantities WITH (NOLOCK)
			WHERE ProductId = @ProductId

			IF ISNULL(@ProductQty,0) <> ISNULL(@StockQtyNumeric,0)
			BEGIN

					SET @OldQty = @OldProductQty
			END

			INSERT INTO InventoryLogs (
					ProductId
					,WarehouseId
					,Description
					,OrderNo
					,InwardNo
					,PurchaseOrderNo
					,Remarks
					,CreatedBy
					,CreatedDate
					,CreatedUTCDate
				)
			VALUES (
					@ProductId
					,@WarehouseId
					,'Inventory has been updated from ' + CAST(@OldProductQty AS NVARCHAR(10)) + ' to ' + CAST((@OldProductQty + @StockQtyNumeric ) AS NVARCHAR(10)) + ' ( +' + CAST(@StockQtyNumeric AS NVARCHAR(10)) + ') by inward Stock file.'
					,NULL
					,@InwardNumber
					,NULL
					,NULL
					,@UserId
					,@DT
					,@DTUTC
				);

			UPDATE WrkInwardProducts
			SET STATUS = 2
				,ErrorMessage = NULL
			WHERE WrkInwardProductID = @WrkInwardProductID;

		END
		ELSE
		BEGIN
			UPDATE WrkInwardProducts
			SET STATUS = 3
				,ErrorMessage = @ErrorMessage
			WHERE WrkInwardProductID = @WrkInwardProductID;

		END

		UPDATE WrkImportFiles
		SET Success = CASE 
				WHEN @ErrorMessage = ''
					THEN ISNULL(Success, 0) + 1
				ELSE ISNULL(Success,0)
				END
			,Failed = CASE 
				WHEN @ErrorMessage <> ''
					THEN ISNULL(Failed, 0) + 1
				ELSE ISNULL(Failed,0)
				END
			,STATUS = 2
			,TotalRecords = @TotalRecords
			,ProcessStartDate = CASE WHEN @ProcessStartDate IS NULL THEN ProcessStartDate ELSE @ProcessStartDate END
			,ProcessEndDate = CASE WHEN @ProcessEndDate IS NULL THEN ProcessEndDate ELSE @ProcessEndDate END
			,UpdatedBy = @UserId
			,UpdatedDate = @dt
			,UpdatedUTCDate = @dtUTC
		WHERE WrkImportFileID = @WrkImportFileID;


		SELECT CASE WHEN @ErrorMessage = '' THEN @ProductId ELSE NULL END AS ProductId
		,@TenantId AS TenantId
		,CASE WHEN @ErrorMessage = '' THEN @TenantLogo ELSE NULL END AS TenantLogo
		,@ErrorMessage AS ErrorMessage

		COMMIT;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK;
		 DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg

		SELECT NULL AS ProductId
		,@TenantId AS TenantId
		,NULL AS TenantLogo
		,@ErrorMessage AS ErrorMessage

	END CATCH
END

GO

