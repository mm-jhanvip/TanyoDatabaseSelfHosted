CREATE   FUNCTION [dbo].[fn_SaleableQuantityByWarehouse]
(
    @ProductId BIGINT
)
RETURNS NUMERIC(18,2)
WITH ENCRYPTION
AS
BEGIN
    DECLARE
        @ReadyToDeliver      NUMERIC(18,2) = 0,
        @WarehouseTotal      NUMERIC(18,2) = 0,
        @ProductSubjectTypeId INT,
        @dt                  DATETIMEOFFSET = SYSDATETIMEOFFSET(),
        @OnHoldCnt           NUMERIC(18,2) = 0,
        @ApprovedQuantities  NUMERIC(18,2) = 0,
        @WarehouseQuantity   NUMERIC(18,2);

    SELECT @ProductSubjectTypeId = SubjectTypeId
    FROM SubjectTypes WITH (NOLOCK)
    WHERE SubjectTypeName = 'Products'
      AND TenantId =
      (
          SELECT TenantId
          FROM Products WITH (NOLOCK)
          WHERE ProductId = @ProductId
      )
      AND IsDeleted = 0;

    -- Warehouse Stock
    SELECT @WarehouseTotal = ISNULL(SUM(Quantity),0)
    FROM ProductQuantitiesByWarehouse WITH (NOLOCK)
    WHERE ProductId = @ProductId;

    -- Ready To Deliver
    SELECT @ReadyToDeliver = ISNULL(SUM(os.Quantity),0)
    FROM Orders o WITH (NOLOCK)
    INNER JOIN OrderSetItems os WITH (NOLOCK)
        ON os.OrderId = o.OrderId
    WHERE os.IsDeleted = 0
      AND os.SubjectId = @ProductId
      AND os.SubjectTypeId = @ProductSubjectTypeId
      AND o.Status = 3
      AND os.ItemStatus = 2;

    -- Approved
    SELECT @ApprovedQuantities = ISNULL(SUM(os.Quantity),0)
    FROM Orders o WITH (NOLOCK)
    INNER JOIN OrderSetItems os WITH (NOLOCK)
        ON os.OrderId = o.OrderId
    WHERE os.IsDeleted = 0
      AND os.SubjectId = @ProductId
      AND os.SubjectTypeId = @ProductSubjectTypeId
      AND (o.Status IN (2) --Approved
	       OR
           (o.Status IN (3) 
            AND os.ItemStatus IN (0,1,4))
        )

    -- On Hold
    SELECT @OnHoldCnt = ISNULL(SUM(vi.Quantity),0)
    FROM vw_HoldItems vi WITH (NOLOCK)
    WHERE vi.SubjectId = @ProductId
      AND vi.HoldUptoDate > @dt;

    SET @WarehouseQuantity =
          ISNULL(@WarehouseTotal,0)
        - ISNULL(@OnHoldCnt,0)
        - ISNULL(@ApprovedQuantities,0)
        - ISNULL(@ReadyToDeliver,0);

    RETURN ISNULL(@WarehouseQuantity,0) ;
END

GO

