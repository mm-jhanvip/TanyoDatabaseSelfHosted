CREATE TABLE [dbo].[fabrics_20260722] (
    [FabricId]        INT                IDENTITY (1, 1) NOT NULL,
    [Title]           VARCHAR (150)      NOT NULL,
    [ModelNo]         VARCHAR (50)       NOT NULL,
    [CompanyId]       INT                NOT NULL,
    [UnitId]          INT                NOT NULL,
    [UnitPrice]       NUMERIC (8, 2)     NOT NULL,
    [ImagePath]       VARCHAR (500)      NULL,
    [TenantId]        INT                NOT NULL,
    [IsDeleted]       BIT                NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]  DATETIME           NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [GST]             NUMERIC (18, 2)    NULL,
    [ImageColorCode]  VARCHAR (15)       NULL,
    [Description]     VARCHAR (MAX)      NULL,
    [RetailerPrice]   NUMERIC (8, 2)     NULL,
    [WholesalerPrice] NUMERIC (8, 2)     NULL
);


GO

