CREATE TABLE [dbo].[ProductMaterials] (
    [ProductMaterialID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]         BIGINT             NOT NULL,
    [SubjectTypeId]     INT                NOT NULL,
    [SubjectId]         INT                NOT NULL,
    [Qty]               NUMERIC (18, 2)    CONSTRAINT [DF__ProductMate__Qty__4830B400] DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) CONSTRAINT [DF__ProductMa__Creat__4A18FC72] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([ProductMaterialID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ProductMaterials_ProductId_SubjectTypeId]
    ON [dbo].[ProductMaterials]([ProductId] ASC, [SubjectTypeId] ASC)
    INCLUDE([SubjectId], [Qty]);


GO

