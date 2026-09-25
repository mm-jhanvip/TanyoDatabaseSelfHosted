CREATE TABLE [dbo].[RawMaterialInventoryByWarehouse] (
    [RawMaterialInventoryByWarehouseId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [RawMaterialId]                     BIGINT             NOT NULL,
    [WarehouseId]                       BIGINT             NOT NULL,
    [QuantityDate]                      DATE               NOT NULL,
    [Quantity]                          INT                NOT NULL,
    [LastModifiedBy]                    BIGINT             NOT NULL,
    [LastModifiedDate]                  DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]               DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([RawMaterialInventoryByWarehouseId] ASC)
);


GO

