CREATE TABLE [dbo].[WrkImportFiles] (
    [WrkImportFileID]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [FileType]         VARCHAR (50)       NOT NULL,
    [ImportFileName]   VARCHAR (200)      NOT NULL,
    [TotalRecords]     INT                NOT NULL,
    [Success]          INT                NULL,
    [Failed]           INT                NULL,
    [ProcessStartDate] DATETIMEOFFSET (7) NULL,
    [ProcessEndDate]   DATETIMEOFFSET (7) NULL,
    [Status]           INT                CONSTRAINT [DF__WrkImport__Statu__53385258] DEFAULT ((0)) NOT NULL,
    [ErrorMessage]     VARCHAR (500)      NULL,
    [TenantId]         INT                NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF__WrkImport__Creat__542C7691] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF__WrkImport__Creat__55209ACA] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        BIGINT             NULL,
    [UpdatedDate]      DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]   DATETIME           NULL,
    [FilePath]         VARCHAR (500)      NULL,
    CONSTRAINT [PK__WrkImpor__FB74E194F20D56FB] PRIMARY KEY CLUSTERED ([WrkImportFileID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_WrkImportFiles_TenantId]
    ON [dbo].[WrkImportFiles]([TenantId] ASC)
    INCLUDE([FileType], [ImportFileName]) WITH (FILLFACTOR = 70);


GO

