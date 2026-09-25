CREATE PROCEDURE [dbo].[SaveProcessOrderAutoPOProducts] (
	@TenantId BIGINT
	,@VendorId BIGINT
	,@UserId BIGINT
	,@OrderId BIGINT
	,@OrderSetItemId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @dt DATETIME = GETDATE()
			,@POProductItems NVARCHAR(MAX)
			,@POProductId BIGINT
			,@OrderNo VARCHAR(100)
			,@SubjectTypeId INT
			,@Message VARCHAR(128)
			,@OutputPOProductId BIGINT

		SELECT @OrderNo = OrderNo
		FROM Orders WITH (NOLOCK)
		WHERE OrderId = @OrderId
			AND TenantId = @TenantId

		DECLARE @TempPOItems TABLE (
			ProductId BIGINT
			,VendorModelNo NVARCHAR(200)
			,Quantity DECIMAL(18, 2)
			,VendorProductPrice DECIMAL(18, 2)
			,ExpectedDeliveryDate DATETIME
			,Status INT
			,Remarks NVARCHAR(500)
			)

		INSERT INTO @TempPOItems
		SELECT P.ProductId
			,ISNULL(PVM.VendorModelNo, P.ModelNo)
			,OSI.Quantity
			,PVM.VendorProductPrice
			,DATEADD(DAY, 7, @dt) AS ExpectedDeliveryDate
			,0 AS Status
			,'' AS Remarks
		FROM OrderSetItems OSI WITH (NOLOCK)
		INNER JOIN Orders ORD WITH (NOLOCK) ON ORD.OrderId = OSI.OrderId
			AND ORD.Status <> 9
		INNER JOIN Products P WITH (NOLOCK) ON P.ProductId = OSI.SubjectId
			AND p.Status <> 3
		INNER JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PVM.ProductId = P.ProductId
			AND pvm.IsDeleted = 0
		INNER JOIN Vendors V WITH (NOLOCK) ON V.VendorId = PVM.VendorId
		INNER JOIN Categories CT WITH (NOLOCK) ON CT.CategoryId = P.CategoryId
			AND CT.IsDeleted = 0
		WHERE OSI.OrderSetItemId = @OrderSetItemId
			AND OSI.IsDeleted = 0
			AND V.IsAutoPoByOrder = 1
			AND OSI.OrderId = @OrderId
			AND ORD.TenantId = @TenantId
			AND V.VendorId = @VendorId
			AND ISNULL(CT.IsManufacturing, 0) = 0

		IF NOT EXISTS (
				SELECT 1
				FROM @TempPOItems
				)
		BEGIN
			SET @Message = 'No eligible products found for auto PO creation.'

			SELECT @Message AS [Message]

			RETURN
		END

		SELECT @POProductItems = (
				SELECT ProductId
					,VendorModelNo
					,Quantity
					,VendorProductPrice
					,ExpectedDeliveryDate
					,Status
					,Remarks
				FROM @TempPOItems
				FOR JSON PATH
				);

		EXEC [dbo].[SavePOProducts] @POProductId = 0
			,@TenantId = @TenantId
			,@VendorId = @VendorId
			,@OrderDate = @dt
			,@Status = 1
			,@UserId = @UserId
			,@POProductItems = @POProductItems
			,@OutputPOProductId = @OutputPOProductId OUTPUT;

		SELECT @POProductId = @OutputPOProductId

		--FROM @TempInsertedPOs
		SELECT @SubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE TenantId = @TenantId
			AND SubjectTypeName = 'POProducts'
			AND IsDeleted = 0

		IF (@POProductId IS NOT NULL)
		BEGIN
			INSERT INTO Comments (
				SubjectTypeId
				,SubjectId
				,Comment
				,Status
				,CreatedBy
				)
			VALUES (
				@SubjectTypeId
				,@POProductId
				,CONCAT (
					'PO has been generated for OrderNo: '
					,@OrderNo
					)
				,0
				,@UserId
				)

			SET @Message = CONCAT (
					'PO created successfully for OrderNo '
					,@OrderNo
					,' with POProductId: '
					,@POProductId
					)

			SELECT @Message AS [Message]
		END
		ELSE
		BEGIN
			SET @Message = 'PO creation failed via SavePOProducts.'

			SELECT @Message AS [Message]
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

