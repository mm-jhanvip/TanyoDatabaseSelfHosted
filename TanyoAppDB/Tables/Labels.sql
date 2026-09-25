CREATE TABLE [dbo].[Labels] (
    [LabelId]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [ColorCode]      VARCHAR (10)       NOT NULL,
    [LabelName]      VARCHAR (100)      NOT NULL,
    [TenantId]       BIGINT             NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    [TagType]        INT                NULL,
    PRIMARY KEY CLUSTERED ([LabelId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Labels_TenantId_IsDeleted]
    ON [dbo].[Labels]([TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([CreatedBy]);


GO

