CREATE TABLE [dbo].[SubjectTypes] (
    [SubjectTypeId]   INT                IDENTITY (1, 1) NOT NULL,
    [SubjectTypeName] VARCHAR (50)       NOT NULL,
    [Comments]        VARCHAR (200)      NOT NULL,
    [TenantId]        INT                NOT NULL,
    [IsDeleted]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__SubjectTy__Creat__1F63A897] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([SubjectTypeId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_SubjectTypes_SubjectTypeName_TenantId_IsDeleted]
    ON [dbo].[SubjectTypes]([SubjectTypeName] ASC, [TenantId] ASC, [IsDeleted] ASC) WITH (FILLFACTOR = 70);


GO

