CREATE TABLE [dbo].[StockTransferDetail] (
    [StockTransferDetailId]     INT                IDENTITY (1, 1) NOT NULL,
    [StockTransferId]           INT                NOT NULL,
    [ProductId]                 BIGINT             NOT NULL,
    [TransferQuantity]          DECIMAL (18, 2)    NOT NULL,
    [ReceivedQuantity]          DECIMAL (18, 2)    NULL,
    [StockTransferDetailStatus] INT                CONSTRAINT [DF_StockTransferItems_StockTransferItemStatus] DEFAULT ((0)) NOT NULL,
    [IsDeleted]                 BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]                 INT                NOT NULL,
    [CreatedDate]               DATETIMEOFFSET (7) CONSTRAINT [DF_StockTransferItems_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [UpdatedBy]                 INT                NULL,
    [UpdatedDate]               DATETIMEOFFSET (7) NULL,
    PRIMARY KEY CLUSTERED ([StockTransferDetailId] ASC)
);


GO

