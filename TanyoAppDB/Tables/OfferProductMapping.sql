CREATE TABLE [dbo].[OfferProductMapping] (
    [OfferProductMappingId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OfferId]               INT                NOT NULL,
    [ProductId]             BIGINT             NOT NULL,
    [LastModifiedBy]        INT                NOT NULL,
    [LastModifiedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OfferProductMappingId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_OfferProductMapping_cover]
    ON [dbo].[OfferProductMapping]([OfferId] ASC, [ProductId] ASC);


GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_U_NC_Product_Offer]
    ON [dbo].[OfferProductMapping]([OfferId] ASC, [ProductId] ASC);


GO

