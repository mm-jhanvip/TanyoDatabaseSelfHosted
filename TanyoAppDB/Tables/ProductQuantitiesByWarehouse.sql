CREATE TABLE [dbo].[ProductQuantitiesByWarehouse] (
    [ProductQuantityByWarehouseId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]                    BIGINT             NOT NULL,
    [WarehouseId]                  BIGINT             NOT NULL,
    [QuantityDate]                 DATE               NOT NULL,
    [Quantity]                     NUMERIC (18, 2)    NOT NULL,
    [LastModifiedBy]               BIGINT             NOT NULL,
    [LastModifiedDate]             DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]          DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]               DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductQuantityByWarehouseId] ASC)
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_U_NC_Product_Warehouse]
    ON [dbo].[ProductQuantitiesByWarehouse]([ProductId] ASC, [WarehouseId] ASC);


GO

CREATE TRIGGER [dbo].[TRG_ProductWareHouseQuantities_Log] ON [dbo].[ProductQuantitiesByWareHouse] 
AFTER INSERT
	,UPDATE
	,DELETE
AS
BEGIN
	SET NOCOUNT ON;


	INSERT INTO TanyoLogs.dbo.ProductWareHouseQuantitiesLog (
		ProductId,
		WarehouseId
		,PreviousQuantity
		,NewQuantity
		,Action
		)
	SELECT COALESCE(I.ProductId, D.ProductId) AS ProductId
		,COALESCE(I.WarehouseId, D.WarehouseId) AS WarehouseId
		,D.Quantity AS PreviousQuantity
		,I.Quantity AS NewQuantity
		,CASE 
			WHEN I.ProductId IS NOT NULL
				AND D.ProductId IS NULL
				THEN 'INSERT'
			WHEN I.ProductId IS NOT NULL
				AND D.ProductId IS NOT NULL
				THEN 'UPDATE'
			WHEN I.ProductId IS NULL
				AND D.ProductId IS NOT NULL
				THEN 'DELETE'
			END AS Action
	FROM inserted I
	FULL OUTER JOIN deleted D ON I.ProductId = D.ProductId
		AND i.WarehouseId = d.WarehouseId
END;

GO

