CREATE TABLE [dbo].[StockTransferLog] (
    [StockTransferId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]       BIGINT             NOT NULL,
    [FromWarehouseId] BIGINT             NOT NULL,
    [ToWarehouseId]   BIGINT             NOT NULL,
    [Quantity]        DECIMAL (18, 2)    NULL,
    [Status]          INT                CONSTRAINT [DF_StockTransfer_Status] DEFAULT ((1)) NOT NULL,
    [TenantId]        BIGINT             NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF_StockTransfer_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           CONSTRAINT [DF_StockTransfer_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_StockTransfer] PRIMARY KEY CLUSTERED ([StockTransferId] ASC)
);


GO

