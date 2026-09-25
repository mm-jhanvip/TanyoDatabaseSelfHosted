CREATE TABLE [dbo].[OrderDeliveryDetails] (
    [OrderDeliveryDetailId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]               BIGINT             NOT NULL,
    [OrderSetItemId]        BIGINT             NOT NULL,
    [ProductId]             BIGINT             NOT NULL,
    [WarehouseId]           INT                NOT NULL,
    [DeliverQuantity]       NUMERIC (18, 2)    NOT NULL,
    [LastModifiedBy]        INT                NOT NULL,
    [LastModifiedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderDeliveryDetailId] ASC)
);


GO

