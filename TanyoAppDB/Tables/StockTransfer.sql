CREATE TABLE [dbo].[StockTransfer] (
    [StockTransferId]     INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]            INT                NOT NULL,
    [StockTransferNo]     VARCHAR (20)       NOT NULL,
    [FromWarehouseId]     INT                NOT NULL,
    [ToWarehouseId]       INT                NOT NULL,
    [Remarks]             NVARCHAR (500)     NULL,
    [StockTransferStatus] INT                CONSTRAINT [DF_StockTransfer_StockTransferStatus] DEFAULT ((0)) NOT NULL,
    [ReceivedBy]          INT                NULL,
    [ReceivedDate]        DATETIMEOFFSET (7) NULL,
    [IsDeleted]           BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]           INT                NOT NULL,
    [CreatedDate]         DATETIMEOFFSET (7) CONSTRAINT [DF_StockTransfer__CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [UpdatedBy]           INT                NULL,
    [UpdatedDate]         DATETIMEOFFSET (7) NULL,
    [TransferDate]        DATE               NULL,
    PRIMARY KEY CLUSTERED ([StockTransferId] ASC),
    CONSTRAINT [CHK_StockTransfer_StatusEnum] CHECK ([StockTransferStatus]=(2) OR [StockTransferStatus]=(1) OR [StockTransferStatus]=(0))
);


GO

