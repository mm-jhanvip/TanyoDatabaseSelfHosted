CREATE TABLE [dbo].[Offers] (
    [OfferId]          INT                IDENTITY (1, 1) NOT NULL,
    [OfferCode]        VARCHAR (50)       NOT NULL,
    [OfferDescription] VARCHAR (2000)     NULL,
    [StartDate]        DATE               NOT NULL,
    [EndDate]          DATE               NOT NULL,
    [MinOrderValue]    INT                NULL,
    [MaxOrderValue]    INT                NULL,
    [OfferPercentage]  INT                DEFAULT ((0)) NOT NULL,
    [OfferCap]         INT                NULL,
    [IsPublished]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]        INT                NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        INT                NULL,
    [UpdatedUTCDate]   DATE               NULL,
    [IsDeleted]        BIT                DEFAULT ((0)) NOT NULL,
    [OfferPerUser]     INT                NULL,
    [TenantId]         INT                NOT NULL,
    [MaxUsers]         INT                NULL,
    [OfferTypeId]      INT                NULL,
    [UpdatedDate]      DATETIMEOFFSET (7) NULL,
    [OfferTitle]       VARCHAR (50)       NULL,
    PRIMARY KEY CLUSTERED ([OfferId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_Offers_Cover]
    ON [dbo].[Offers]([TenantId] ASC, [OfferId] ASC, [IsDeleted] ASC, [IsPublished] ASC);


GO

