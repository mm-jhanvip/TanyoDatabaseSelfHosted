CREATE TABLE [dbo].[ProductVariants] (
    [Id]               BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductVariantId] BIGINT             NOT NULL,
    [ProductId]        INT                NOT NULL,
    [CreatedBy]        INT                NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF__ProductVa__Creat__48FABB07] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF__ProductVa__Creat__49EEDF40] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK__ProductV__3214EC07DC13BE0A] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_ProductVariants_Cover]
    ON [dbo].[ProductVariants]([ProductId] ASC)
    INCLUDE([ProductVariantId]) WITH (FILLFACTOR = 70);


GO

