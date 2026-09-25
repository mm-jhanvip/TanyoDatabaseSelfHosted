
/*
EXEC [AutoCreatePurchaseOrder_V2]
	@POProductId = 7
	,@TenantId = 2
    ,@UserId = 5

*/
CREATE PROC [dbo].[AutoCreatePurchaseOrder_V2] (
	@POProductId BIGINT
	,@TenantId BIGINT
	,@UserId INT
	,@Status BIT = 0 OUTPUT
	,@Message VARCHAR(MAX) = '' OUTPUT
	,@OrderID BIGINT = 0 OUTPUT
	,@ReturnPOProductId BIGINT = 0 OUTPUT
	,@UnmappedProductsFlag BIT = 0 OUTPUT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @VendorId BIGINT
		,@VendorTenantId INT
		,@ProductSubjectId INT
		,@ReturnStatus BIT
		,@LocationID BIGINT
		,@DealerSalesmanId BIGINT
		,@POJSONObject NVARCHAR(MAX)
		,@DealerCustomerId BIGINT
		,@ReturnOrderID BIGINT = 0
		,@Now DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@NowUTC DATETIME = GETUTCDATE()
		,@UnPublishedProducts NVARCHAR(MAX)
		,@UnmappedProducts NVARCHAR(MAX);

	DROP TABLE IF EXISTS #UnmappedProducts
	DROP TABLE IF EXISTS #OrderSetItemMapping

	-- 1. Resolve Vendor Details
	SELECT @VendorId = p.VendorId
	FROM dbo.POProducts p WITH (NOLOCK)
	WHERE p.POProductId = @POProductId
		AND p.TenantId = @TenantId
		AND p.IsDeleted = 0;

	SELECT @VendorTenantId = VendorTenantID
	FROM Vendors WITH (NOLOCK)
	WHERE VendorId = @VendorId

	CREATE TABLE #UnmappedProducts (
		POProductItemId BIGINT
		,DealerProductId BIGINT
		,VendorProductId BIGINT
		,ProductInfo NVARCHAR(MAX)
		,IsUnmappedProducts BIT
		)

	INSERT INTO #UnmappedProducts (
		POProductItemId
		,DealerProductId
		,VendorProductId
		,ProductInfo
		,IsUnmappedProducts
		)
	SELECT pit.POProductItemId
		,pit.ProductId AS DealerProductId
		,PT.ProductId AS VendorProductId
		,CONCAT (
			'Product Title: '
			,PTIP.ProductTitle
			,' Product ModelNo: '
			,PTIP.ModelNo
			,' VendorModelNo: - ('
			,PVM.VendorModelNo
			,')'
			) AS ProductInfo
		,CASE 
			WHEN PVM.ProductId IS NULL THEN 1
			END AS IsUnmappedProducts
	FROM POProductItems PIT WITH (NOLOCK)
	LEFT JOIN Products PTIP WITH (NOLOCK) ON PTIP.ProductId = PIT.ProductId
		AND PTIP.TenantId = @TenantId
	LEFT JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PIT.ProductId = PVM.ProductId
		AND PVM.VendorId = @VendorId
		AND PVM.IsDeleted = 0
	LEFT JOIN Products PT WITH (NOLOCK) ON PT.ModelNo = PVM.VendorModelNo
		AND PT.STATUS <> 1
		AND PT.TenantId = @VendorTenantId
	WHERE PIT.POProductId = @POProductId

	IF EXISTS (SELECT 1 FROM #UnmappedProducts)
	BEGIN

		IF EXISTS (SELECT 1 FROM #UnmappedProducts WHERE IsUnmappedProducts = 1)
		BEGIN
			SELECT @UnmappedProducts = STRING_AGG(ProductInfo, ',')
			FROM #UnmappedProducts
			WHERE IsUnmappedProducts = 1;

			SET @UnmappedProductsFlag = 1;
			SET @Message = '';
			SET @Status = 0;
			SET @ReturnPOProductId = @POProductId;

			RETURN;
		END
	END

	IF ISNULL(@VendorTenantId, 0) = 0
	BEGIN
		UPDATE POProducts
		SET STATUS = 2
			,UpdatedBy = @UserId
			,UpdatedDate = @Now
			,UpdatedUTCDate = @NowUTC
		WHERE POProductId = @POProductId
			AND TenantId = @TenantId;

		UPDATE POProductItems
		SET STATUS = 2
			,UpdatedBy = @UserId
			,UpdatedDate = @Now
			,UpdatedUTCDate = @NowUTC
		WHERE POProductId = @POProductId;

		SET @Status = 1;
		SET @Message = 'PO approved successfully.';
		SET @ReturnPOProductId = @POProductId

		RETURN;
	END

	-- 2. Setup Meta Attributes & Relationships
	SELECT @ProductSubjectId = SubjectTypeId
	FROM SubjectTypes WITH (NOLOCK)
	WHERE SubjectTypeName = 'Products'
		AND TenantId = @VendorTenantId

	SELECT @DealerSalesmanId = v.SalesmanId
	FROM Vendors V WITH (NOLOCK)
	WHERE V.TenantId = @VendorTenantId
		AND V.IsDealer = 1
		AND V.AcceptRejectStatus = 1
		AND EXISTS (
			SELECT 1
			FROM Customers C WITH (NOLOCK)
			WHERE V.DealerCustomerId = C.CustomerId
				AND C.TenantId = @VendorTenantId
				AND C.CustomerTypeId = 4
				AND C.CustomerTenantID = @TenantId
			);

	SELECT @LocationID = LocationID
	FROM LocationUserMapping WITH (NOLOCK)
	WHERE UserId = @DealerSalesmanId
		AND IsDefault = 1;

	SELECT @DealerCustomerId = c.CustomerId
	FROM Customers C WITH (NOLOCK)
	WHERE C.TenantId = @VendorTenantId
		AND C.CustomerTypeId = 4
		AND C.CustomerTenantID = @TenantId
		AND EXISTS (
			SELECT 1
			FROM Vendors V WITH (NOLOCK)
			WHERE V.DealerCustomerId = C.CustomerId
				AND V.IsDealer = 1
				AND V.AcceptRejectStatus = 1
			)

	SELECT @UnPublishedProducts = STRING_AGG(ProductInfo, ',')
	FROM #UnmappedProducts
	WHERE VendorProductId IS NOT NULL

	IF EXISTS (SELECT 1 FROM #UnmappedProducts)
	BEGIN
		IF EXISTS (SELECT 1 FROM #UnmappedProducts WHERE VendorProductId IS NOT NULL)
		BEGIN
			SET @UnmappedProductsFlag = 0;
			SET @Status = 0;
			SET @Message = 'These products ' + ISNULL(@UnPublishedProducts, '') + ' are not available, please contact Vendor.';
			SET @ReturnPOProductId = @POProductId;

			RETURN;
		END
	END

	IF EXISTS (
			 SELECT 1
			FROM POProductItems PIT WITH (NOLOCK)
			LEFT JOIN ProductVendorMapping PVM WITH (NOLOCK) 
				ON PIT.ProductId = PVM.ProductId
				AND PVM.VendorId = @VendorId
				AND PVM.IsDeleted = 0
			LEFT JOIN Products PT WITH (NOLOCK) 
				ON PT.ModelNo = PVM.VendorModelNo
				AND PT.TenantId = @VendorTenantId
			WHERE PIT.POProductId = @POProductId
				AND PT.ProductId IS NULL
			)
	BEGIN

		SET @Status = 0;
		SET @Message = 'One or more products are not available. Please contact the vendor for further details.';
		SET @ReturnPOProductId = @POProductId;
		RETURN;
	END

	BEGIN TRY
		SELECT @POJSONObject = (
				SELECT 0 AS OrderId
					,@DealerCustomerId AS CustomerID
					,0 AS BillingAddressID
					,0 AS ShippingAddressID
					,'' AS Comments
					,0 AS DeliveryAmount
					,1 AS DeliveryCharge -- Free
					,NULL AS DeliveryCharges
					,0 AS discount
					,PO.TotalAmount AS TotalAmount
					,PO.ExpectedDeliveryDate AS TentativeDeliveryDate
					,(
						SELECT 0 AS OrderSetId
							,'POSet' AS SetName
							,1 AS groupId
							,(
								SELECT 0 AS OrderSetItemId
									,0 AS ParentOrderSetItemId
									,1 AS parentGroupId
									,ROW_NUMBER() OVER (
										ORDER BY PT.ProductId
										) AS groupId
									,@ProductSubjectId AS SubjectTypeId
									,PT.ProductId AS SubjectId
									,PIT.Width AS Width
									,PIT.Height AS Height
									,PIT.Depth AS Depth
									,PIT.Diameter AS Diameter
									,PIT.Quantity AS Quantity
									,PIT.UnitPrice AS UnitPrice
									,PIT.UnitPrice * Quantity AS TotalAmount
									,PIT.UnitPrice * Quantity AS GrossTotal
									,0 AS Discount
									,0 AS DiscountPrice
									,PIT.Remarks AS Comment
									,NULL AS OfferId
									,NULL AS ProvidedMaterial
									,NULL AS ReceiveDate
									,PT.CoverImage AS ProductImage
									,JSON_QUERY('[]') AS AddOns
									,PT.Width AS InstantWidth
									,PT.Height AS InstantHeight
									,PT.Depth AS InstantDepth
									,PT.Diameter AS InstantDiameter
									,PT.WholesalerPrice AS InstantUnitPrice
									,PT.CostPrice AS InstantCostPrice
									,PIT.UnitPrice AS UnitSalePrice
									-- FIX #2: Wrapped ISNULL nested JSON array with JSON_QUERY
									,JSON_QUERY(ISNULL((
										SELECT POProductItemId
											,FileURL
											,IsImage
										FROM POProductItemsAttachments poia WITH (NOLOCK)
										WHERE poia.POProductItemId = pit.POProductItemId
											AND IsDeleted = 0
										FOR JSON PATH
									),'[]')) AS Attachments									
								FROM POProductItems PIT WITH (NOLOCK)
								INNER JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PIT.ProductId = PVM.ProductId
									AND PVM.VendorId = @VendorId
									AND PVM.IsDeleted = 0
								INNER JOIN Products PT WITH (NOLOCK) ON PT.ModelNo = PVM.VendorModelNo
									AND PT.STATUS <> 3
									AND PT.TenantId = @VendorTenantId
								WHERE PIT.POProductId = @POProductId
								FOR JSON PATH
								) AS OrderSetItemRequestDto
						FOR JSON PATH
						) AS OrderSetRequestDto
				FROM POProducts PO WITH (NOLOCK)
				WHERE PO.POProductId = @POProductId
					AND PO.IsDeleted = 0
				FOR JSON PATH
					,WITHOUT_ARRAY_WRAPPER
				);

		EXEC SaveOrder_V2 @OrderID = 0
			,@OrderType = 'W'
			,@TenantID = @VendorTenantId
			,@UserID = @DealerSalesmanId
			,@RefreshInquiry = 0
			,@JsonObject = @POJSONObject
			,@LocationID = @LocationID
			,@isFromBackOrder = 0
			,@ReturnOrderID = @ReturnOrderID OUTPUT
			,@ReturnStatus = @ReturnStatus OUTPUT;

		SELECT OSI.OrderSetItemId AS VendorOrderSetItemId
			,POI.POProductItemId
			,POI.ProductId AS DealerProductId
		INTO #OrderSetItemMapping
		FROM POProductItems POI WITH (NOLOCK)
		INNER JOIN ProductVendorMapping PVM WITH (NOLOCK) ON PVM.ProductId = POI.ProductId AND PVM.VendorId = @VendorId
		INNER JOIN Products PT WITH (NOLOCK) ON PT.ModelNo = PVM.VendorModelNo AND PT.TenantId = @VendorTenantId
		INNER JOIN OrderSetItems OSI WITH (NOLOCK) ON OSI.SubjectId = PT.ProductId AND OSI.SubjectTypeId = @ProductSubjectId
		WHERE OSI.OrderId = @ReturnOrderID
			AND OSI.IsDeleted = 0
			AND POI.POProductId = @POProductId;

		UPDATE POProducts
		SET STATUS = 2
			,UpdatedBy = @UserId
			,UpdatedDate = @Now
			,UpdatedUTCDate = @NowUTC
			,VendorOrderId = @ReturnOrderID
		WHERE POProductId = @POProductId
			AND TenantId = @TenantId;

		UPDATE POI
		SET POI.STATUS = 2
			,POI.UpdatedBy = @UserId
			,POI.UpdatedDate = @Now
			,POI.UpdatedUTCDate = @NowUTC
			,POI.VendorOrderSetItemId = OSI.VendorOrderSetItemId
		FROM POProductItems POI
		INNER JOIN #OrderSetItemMapping OSI ON OSI.POProductItemId = POI.POProductItemId
		WHERE POProductId = @POProductId;

		SET @UnmappedProductsFlag = 0;
		SET @Status = 1;
		SET @Message = 'PO approved successfully.';
		SET @OrderID = @ReturnOrderID;
		SET @ReturnPOProductId = @POProductId;

	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500);

		SET @Status = 0;
		SET @Message = ERROR_MESSAGE();
		SET @OrderID = @ReturnOrderID;
		SET @ReturnPOProductId = @POProductId;
		SET @ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @Message;
	END CATCH
END

GO

