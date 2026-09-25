CREATE TABLE [dbo].[Catalogue] (
    [CatalogueId]                  BIGINT             IDENTITY (1, 1) NOT NULL,
    [CatalogueName]                VARCHAR (50)       NOT NULL,
    [TenantId]                     INT                NOT NULL,
    [IsDeleted]                    BIT                NOT NULL,
    [CreatedBy]                    BIGINT             NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]               DATETIME           NOT NULL,
    [ProductPriceType]             TINYINT            NULL,
    [UpdatedBy]                    BIGINT             NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [ShowProductStockAvailability] BIT                CONSTRAINT [DF_Catalogue_ShowProductStockAvailability] DEFAULT ((0)) NOT NULL,
    [ShowSimilarProducts]          BIT                CONSTRAINT [DF_Catalogue_ShowSimilarProducts] DEFAULT ((0)) NOT NULL
);


GO

