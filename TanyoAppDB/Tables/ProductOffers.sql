CREATE TABLE [dbo].[ProductOffers] (
    [Id]              INT          IDENTITY (1, 1) NOT NULL,
    [ProductId]       BIGINT       NOT NULL,
    [TenantId]        INT          NOT NULL,
    [OfferId]         INT          NOT NULL,
    [StartDate]       DATE         NOT NULL,
    [EndDate]         DATE         NOT NULL,
    [OfferPercentage] INT          NOT NULL,
    [OfferCode]       VARCHAR (50) NOT NULL,
    [CreatedDate]     DATETIME     NULL,
    CONSTRAINT [PK__ProductO__3214EC075E720145] PRIMARY KEY CLUSTERED ([ProductId] ASC)
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [IDX_ProductOffers]
    ON [dbo].[ProductOffers]([ProductId] ASC, [TenantId] ASC)
    INCLUDE([OfferId], [StartDate], [EndDate], [OfferPercentage], [OfferCode]);


GO

