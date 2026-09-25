CREATE TABLE [dbo].[Fabrics] (
    [FabricId]        INT                IDENTITY (1, 1) NOT NULL,
    [Title]           VARCHAR (150)      NOT NULL,
    [ModelNo]         VARCHAR (50)       NOT NULL,
    [CompanyId]       INT                NOT NULL,
    [UnitId]          INT                NOT NULL,
    [UnitPrice]       NUMERIC (8, 2)     NOT NULL,
    [ImagePath]       VARCHAR (500)      NULL,
    [TenantId]        INT                NOT NULL,
    [IsDeleted]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__Fabrics__Created__00AA174D] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [GST]             NUMERIC (18, 2)    CONSTRAINT [df_Fabrics_SGSTAmount] DEFAULT ((18)) NULL,
    [ImageColorCode]  VARCHAR (15)       CONSTRAINT [DF_Fabrics_ImageColorCode] DEFAULT ('0,0,0') NULL,
    [Description]     VARCHAR (MAX)      NULL,
    [RetailerPrice]   NUMERIC (8, 2)     NULL,
    [WholesalerPrice] NUMERIC (8, 2)     NULL,
    PRIMARY KEY CLUSTERED ([FabricId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Fabrics_CompanyId_TenantId_IsDeleted]
    ON [dbo].[Fabrics]([CompanyId] ASC, [TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([Title], [ModelNo], [UnitId], [UnitPrice], [ImagePath], [GST]) WITH (FILLFACTOR = 80);


GO

