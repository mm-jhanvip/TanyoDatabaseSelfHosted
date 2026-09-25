/*  
EXEC [dbo].[GetInventoryDetailsByProduct]        
@TenantId = 1207,    
@ProductId = 402888;    
*/
CREATE PROCEDURE [dbo].[GetInventoryDetailsByProduct] (
	@TenantId BIGINT
	,@ProductId BIGINT
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;

		DECLARE @dt DATETIMEOFFSET = SYSDATETIMEOFFSET();
		DECLARE @ProductSubjectTypeId INT;
		DECLARE @ApprovedQuantities NUMERIC(18, 2) = 0
			,@ReadyToDelivered NUMERIC(18, 2) = 0
			,@OnHoldCnt NUMERIC(18, 2) = 0
			,@WarehouseTotal NUMERIC(18, 2) = 0
			,@FinalTotal NUMERIC(18, 2) = 0
			,@WarehouseId BIGINT
			,@WareHouseCount INT;

		DROP TABLE IF EXISTS #WareHouse;

		CREATE TABLE #WareHouse (WAREHOUSEID BIGINT);

		-- 1. Get SubjectTypeId for 'Products'  
		SELECT @ProductSubjectTypeId = SubjectTypeId
		FROM dbo.SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		INSERT INTO #WareHouse (WareHouseId)
		SELECT WarehouseId
		FROM dbo.ProductQuantitiesByWarehouse WITH (NOLOCK)
		WHERE ProductId = @ProductId;

		-- 2. Calculate Approved Quantities 
		SELECT @ApprovedQuantities = ISNULL(SUM(os.Quantity), 0)
		FROM dbo.Orders o WITH (NOLOCK)
		INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
		WHERE o.TenantId = @TenantId
			AND os.IsDeleted = 0
			AND os.SubjectId = @ProductId
			AND os.SubjectTypeId = @ProductSubjectTypeId
			AND (
				o.Status IN (2) -- Approved  
				OR (
					o.Status IN (3) -- InProgress  
					AND os.ItemStatus IN (
						0
						,1
						,4
						) -- ReadyToManufacturing, Manufacturing, Pending  
					)
				);

		SELECT @ReadyToDelivered = ISNULL(SUM(os.Quantity), 0)
		FROM dbo.Orders o WITH (NOLOCK)
		INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
		WHERE o.TenantId = @TenantId
			AND os.IsDeleted = 0
			AND os.SubjectId = @ProductId
			AND os.SubjectTypeId = @ProductSubjectTypeId
			AND o.Status IN (3)
			AND os.ItemStatus = 2;

		SELECT @OnHoldCnt = ISNULL(SUM(vh.Quantity), 0)
		FROM dbo.vw_HoldItems vh WITH (NOLOCK)
		WHERE vh.TenantId = @TenantId
			AND vh.HoldUptoDate > @dt
			AND vh.SubjectId = @ProductId;

		SELECT @WarehouseTotal = ISNULL(SUM(Quantity), 0)
		FROM dbo.ProductQuantitiesByWarehouse WITH (NOLOCK)
		WHERE ProductId = @ProductId;

		SET @FinalTotal = ISNULL(@WarehouseTotal, 0) - ISNULL(@OnHoldCnt, 0) - ISNULL(@ApprovedQuantities, 0) - ISNULL(@ReadyToDelivered, 0);

		--SET @OnHoldCnt = CASE WHEN @OnHoldCnt > 0 THEN cast(concat('-',@OnHoldCnt) as nvarchar(20)) ELSE @OnHoldCnt END
		--SET @ApprovedQuantities = CASE WHEN @ApprovedQuantities > 0 THEN cast(concat('-',@ApprovedQuantities) as nvarchar(20)) ELSE @ApprovedQuantities END
		--SET @ReadyToDelivered = CASE WHEN @ReadyToDelivered > 0 THEN cast(concat('-',@ReadyToDelivered) as nvarchar(20)) ELSE @ReadyToDelivered END
		--IF @FinalTotal < 0 
		--       SET @FinalTotal = 0;
		SELECT C.CategoryName
			,CAST(CASE 
					WHEN C.CategoryTypeId = 2
						THEN 1
					ELSE 0
					END AS BIT) AS IsFabric
			,P.ProductTitle AS ProductName
			,PQ.MinimumLimit AS ReorderPoint
			,ISNULL(PQ.ProductQuantityId, 0) AS ProductQuantityId
			,@FinalTotal AS CurrentQuantity
			,@FinalTotal AS UpdateQuantity
			,@OnHoldCnt AS OnHoldQuantities
			,@ApprovedQuantities AS ApprovedQuantities
			,@ReadyToDelivered AS ReadyToDeliver
			,@FinalTotal AS TotalSaleableQuantity
			,W.Id AS WarehouseId
			,W.Name AS WarehouseName
			,ISNULL(PQBW.ProductQuantityByWarehouseId, 0) AS ProductQuantityByWarehouseId
			,ISNULL(PQBW.Quantity, 0) AS WarehouseCurrentQuantity
			,ISNULL(PQBW.Quantity, 0) AS WarehouseUpdateQuantity
			,@WarehouseTotal AS TotalWarehouseQuantity
		FROM dbo.Products P WITH (NOLOCK)
		INNER JOIN dbo.Categories C WITH (NOLOCK) ON C.CategoryId = P.CategoryId
			AND C.TenantId = @TenantId
		INNER JOIN dbo.ProductQuantities PQ WITH (NOLOCK) ON PQ.ProductId = P.ProductId
		INNER JOIN dbo.Warehouse W WITH (NOLOCK) ON W.TenantId = @TenantId
			AND W.IsDeleted = 0
		LEFT JOIN dbo.ProductQuantitiesByWarehouse PQBW WITH (NOLOCK) ON PQBW.WarehouseId = W.Id
			AND PQBW.ProductId = P.ProductId
		WHERE P.TenantId = @TenantId
			AND P.ProductId = @ProductId
		ORDER BY W.Name ASC;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

