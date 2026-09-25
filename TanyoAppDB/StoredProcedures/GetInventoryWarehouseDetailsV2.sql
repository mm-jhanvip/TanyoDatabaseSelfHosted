/*
    EXEC [dbo].[GetInventoryWarehouseDetailsV2] 
	    @ProductId = 402805
	    ,@WarehouseId = NULL
*/
CREATE PROCEDURE [dbo].[GetInventoryWarehouseDetailsV2]
    @ProductId BIGINT
    ,@WarehouseId BIGINT = NULL
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
    SET NOCOUNT ON;

    DECLARE @ReadyToDeliver NUMERIC(18,2) = 0
            ,@WarehouseTotal NUMERIC(18,2) = 0
            ,@ProductSubjectTypeId INT = 0
	        ,@dt DATETIMEOFFSET
            ,@OnHoldCnt NUMERIC(18,2) 
            ,@ApprovedQuantities NUMERIC(18,2) 

    SELECT @dt = SYSDATETIMEOFFSET()
            
    SELECT @ProductSubjectTypeId = SubjectTypeId
	FROM SubjectTypes WITH (NOLOCK)
	WHERE SubjectTypeName = 'Products'
	AND TenantId = (SELECT TenantId FROM Products WITH (NOLOCK) WHERE ProductId = @ProductId)
	AND IsDeleted = 0

	DROP TABLE IF EXISTS #Result
	
    CREATE TABLE #Result (
        ID INT IDENTITY
        ,WarehouseId BIGINT
        ,WarehouseName NVARCHAR(255)
        ,Quantity NUMERIC(18,2)
        ,IsTotal BIT Default 0
        ,IsExclude BIT Default 0
        ,IsDefault BIT Default 0
    )

    INSERT INTO #Result (WarehouseId, WarehouseName, Quantity, IsDefault)
    SELECT 
        w.Id
        ,W.Name AS WarehouseName
        ,PW.Quantity
        ,W.IsDefault
    FROM ProductQuantitiesByWarehouse PW WITH (NOLOCK)
    INNER JOIN Warehouse W WITH (NOLOCK) ON PW.WarehouseId = W.Id
    WHERE PW.ProductId = @ProductId
    AND (@WarehouseId IS NULL OR @WarehouseId = -1 OR PW.WarehouseId = @WarehouseId)
    ORDER BY W.Name

    -- If no default warehouse exists in the result,
    -- mark 'Other' as default
    IF NOT EXISTS (
        SELECT 1
        FROM #Result
        WHERE IsDefault = 1
    )
    BEGIN
        UPDATE #Result
        SET IsDefault = 1
        WHERE WarehouseName = 'Other';
    END

    SELECT @WarehouseTotal = SUM(Quantity)
    FROM ProductQuantitiesByWarehouse WITH (NOLOCK)
    WHERE ProductId = @ProductId
    AND (@WarehouseId IS NULL OR @WarehouseId = -1 OR WarehouseId = @WarehouseId)

    SELECT @ReadyToDeliver = ISNULL(SUM(os.Quantity),0)
    FROM dbo.Orders o WITH (NOLOCK)
	INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
	WHERE os.IsDeleted = 0
	AND os.SubjectId = @ProductId
    AND os.SubjectTypeId = @ProductSubjectTypeId
    AND (o.Status IN (3) AND os.ItemStatus = 2) --Order: InProgress, Item: Ready to Deliver

    SELECT @ApprovedQuantities = ISNULL(SUM(os.Quantity),0)
    FROM dbo.Orders o WITH (NOLOCK)
	INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
	WHERE os.IsDeleted = 0
	AND os.SubjectId = @ProductId
    AND os.SubjectTypeId = @ProductSubjectTypeId
    AND (o.Status IN (2) --Approved
	       OR
           (o.Status IN (3) 
            AND os.ItemStatus IN (0,1,4))
        )
            /*
            0 = ReadyToManufacturing
            1 = Manufacturing
            2 = ReadyToDeliver
            3 = Delivered
            4 = Pending
            */

	SELECT @OnHoldCnt = ISNULL(SUM(vi.Quantity),0)
	FROM vw_HoldItems vi WITH (NOLOCK)
	WHERE vi.SubjectId = @ProductId
	AND vi.HoldUptoDate > @dt
	AND vi.SubjectId = @ProductId


    INSERT INTO #Result (WarehouseId, WarehouseName, Quantity, IsExclude)
    VALUES (-2, 'On Hold Quantities', @OnHoldCnt, 1)

    INSERT INTO #Result (WarehouseId, WarehouseName, Quantity, IsExclude)
    VALUES (-3, 'Approved Quantities', @ApprovedQuantities, 1)

    INSERT INTO #Result (WarehouseId, WarehouseName, Quantity, IsExclude)
    VALUES (-4, 'Ready To Deliver', @ReadyToDeliver, 1)


    DECLARE @FinalTotal NUMERIC(18,2)

    IF ISNULL(@WarehouseId,0) > 0 BEGIN
        SELECT @FinalTotal = Quantity
        FROM ProductQuantities 
        where ProductId = @ProductId
    END ELSE BEGIN
    SET @FinalTotal = ISNULL(@WarehouseTotal, 0) 
                    - ISNULL(@OnHoldCnt, 0) 
                    - ISNULL(@ApprovedQuantities, 0)
                    - ISNULL(@ReadyToDeliver, 0)
    END
    SET @FinalTotal = ISNULL(@FinalTotal, 0)

    INSERT INTO #Result (WarehouseId, WarehouseName, Quantity, IsTotal, IsExclude)
    VALUES (-5, 'Total', @FinalTotal, 1, 1)

    SELECT r.WarehouseId
        ,r.WarehouseName
        ,r.Quantity
        ,r.IsTotal
        ,r.IsExclude
        ,r.IsDefault
    FROM #Result r
    ORDER BY 
        CASE 
            WHEN r.WarehouseName = 'Other' THEN 3
            WHEN r.WarehouseId = -2 THEN 4
            WHEN r.WarehouseId = -3 THEN 5
            WHEN r.WarehouseId = -4 THEN 6
            WHEN r.WarehouseId = -5 THEN 7
            ELSE 1 END
        ,r.ID

    DROP TABLE #Result

    END TRY

	BEGIN CATCH
		IF OBJECT_ID('tempdb..#Result') IS NOT NULL
			DROP TABLE #Result;

		DECLARE @ObjectName VARCHAR(400),
				@ERRORMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

