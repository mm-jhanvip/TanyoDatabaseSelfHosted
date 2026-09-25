CREATE TABLE [dbo].[InventoryLogs] (
    [InventoryLogId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]       BIGINT             NOT NULL,
    [WarehouseId]     BIGINT             NULL,
    [Description]     VARCHAR (500)      NOT NULL,
    [OrderNo]         VARCHAR (50)       NULL,
    [InwardNo]        VARCHAR (50)       NULL,
    [PurchaseOrderNo] VARCHAR (50)       NULL,
    [Remarks]         NVARCHAR (500)     NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF_InventoryLogs_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           CONSTRAINT [DF_InventoryLogs_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [STOCKTRANSFERNO] VARCHAR (50)       NULL,
    PRIMARY KEY CLUSTERED ([InventoryLogId] ASC)
);


GO

