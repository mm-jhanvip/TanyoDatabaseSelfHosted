CREATE TABLE [dbo].[RawMaterials] (
    [RawMaterialId]  INT                                                 IDENTITY (1, 1) NOT NULL,
    [Title]          VARCHAR (150)                                       NOT NULL,
    [UnitId]         INT                                                 NOT NULL,
    [UnitPrice]      NUMERIC (8, 2) NOT NULL,
    [ImagePath]      VARCHAR (500)                                       NULL,
    [TenantId]       INT                                                 NOT NULL,
    [IsDeleted]      BIT                                                 DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                                                 NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7)                                  CONSTRAINT [DF__RawMateri__Creat__7BE56230] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME                                            DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                                                 NULL,
    [UpdatedDate]    DATETIMEOFFSET (7)                                  NULL,
    [UpdatedUTCDate] DATETIME                                            NULL,
    [VendorId]       BIGINT                                              NULL,
    [IsConsumable]   BIT                                                 DEFAULT ((0)) NOT NULL,
    [MaterialType]   INT                                                 DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RawMaterialId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_RawMaterials_TenantId_IsDeleted]
    ON [dbo].[RawMaterials]([TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([Title], [UnitId], [UnitPrice], [ImagePath], [CreatedDate]) WITH (FILLFACTOR = 80);


GO

