CREATE TABLE [dbo].[PriceChangeLogs] (
    [PriceChangeLogId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [EntityID]         BIGINT             NOT NULL,
    [OldValue]         DECIMAL (18, 2)    NOT NULL,
    [NewValue]         DECIMAL (18, 2)    NOT NULL,
    [CreatedBy]        INT                NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_UpdateProductPrice_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF_UpdateProductPrice_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [EntityTypeID]     BIGINT             NULL,
    CONSTRAINT [PK_UpdateProductPrice] PRIMARY KEY CLUSTERED ([PriceChangeLogId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_PriceChangeLogs_EntityId_CreatedBy]
    ON [dbo].[PriceChangeLogs]([EntityID] ASC, [CreatedBy] ASC) WITH (FILLFACTOR = 80);


GO

