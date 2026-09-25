CREATE TABLE [dbo].[CatalogueDetails] (
    [CatalogueDetailId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CatalogueId]       BIGINT             NOT NULL,
    [ProductId]         BIGINT             NOT NULL,
    [IsDeleted]         BIT                NOT NULL,
    [CreatedBy]         BIGINT             NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]    DATETIME           NOT NULL,
    [UpdatedBy]         BIGINT             NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL
);


GO

CREATE CLUSTERED INDEX [IX_C_CatalogueDetails]
    ON [dbo].[CatalogueDetails]([CatalogueId] ASC);


GO

CREATE NONCLUSTERED INDEX [IX_NC_CatalogueDetails_Cover]
    ON [dbo].[CatalogueDetails]([CatalogueId] ASC, [ProductId] ASC, [IsDeleted] ASC)
    INCLUDE([CatalogueDetailId]);


GO

