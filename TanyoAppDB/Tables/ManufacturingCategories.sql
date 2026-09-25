CREATE TABLE [dbo].[ManufacturingCategories] (
    [ManufacturingCategoriesID] INT                IDENTITY (1, 1) NOT NULL,
    [CategoryName]              VARCHAR (50)       NOT NULL,
    [TenantId]                  BIGINT             NOT NULL,
    [IsDeleted]                 BIT                NOT NULL,
    [CreatedBy]                 BIGINT             NOT NULL,
    [CreatedDate]               DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]            DATETIME           NOT NULL,
    [UpdatedBy]                 BIGINT             NULL,
    [UpdatedDate]               DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]            DATETIME           NULL,
    CONSTRAINT [PK_ManufacturingCategories] PRIMARY KEY CLUSTERED ([ManufacturingCategoriesID] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_ManufacturingCategories_TenantId_IsDeleted]
    ON [dbo].[ManufacturingCategories]([TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([CreatedBy]);


GO

