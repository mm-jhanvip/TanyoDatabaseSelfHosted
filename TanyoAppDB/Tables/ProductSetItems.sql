CREATE TABLE [dbo].[ProductSetItems] (
    [ProductSetItemId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductSetId]     BIGINT             NOT NULL,
    [ProductId]        BIGINT             NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_ProductSetItems_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF_ProductSetItems_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [Quantity]         NUMERIC (18, 2)    DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductSetItemId] ASC)
);


GO

