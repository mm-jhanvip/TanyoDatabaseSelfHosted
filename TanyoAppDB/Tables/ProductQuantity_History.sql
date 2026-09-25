CREATE TABLE [dbo].[ProductQuantity_History] (
    [HistoryId]           BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductQuantityId]   BIGINT             NULL,
    [ProductId]           BIGINT             NULL,
    [QuantityDate]        DATETIMEOFFSET (7) NULL,
    [Quantity]            NUMERIC (18, 4)    NULL,
    [LastModifiedBy]      BIGINT             NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) NULL,
    [LastModifiedUTCDate] DATETIME           NULL,
    [MinimumLimit]        INT                NULL,
    [UpdatedOn]           DATETIME           DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([HistoryId] ASC)
);


GO

