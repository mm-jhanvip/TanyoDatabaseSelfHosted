CREATE TABLE [dbo].[WrkImportFabrics] (
    [WrkCustomerID]   BIGINT                                             IDENTITY (1, 1) NOT NULL,
    [WrkImportFileID] BIGINT                                             NOT NULL,
    [Title]           VARCHAR (MAX)                                      NULL,
    [ModelNo]         VARCHAR (MAX)                                      NULL,
    [CompanyName]     VARCHAR (MAX)                                      NULL,
    [UnitName]        VARCHAR (MAX)                                      NULL,
    [Price]           VARCHAR (MAX) NULL,
    [Status]          INT                                                DEFAULT ((0)) NOT NULL,
    [ErrorMessage]    VARCHAR (MAX)                                      NULL,
    [CreatedBy]       BIGINT                                             NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7)                                 CONSTRAINT [DF__WrkImport__Creat__5DB5E0CB] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME                                           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       BIGINT                                             NULL,
    [UpdatedDate]     DATETIMEOFFSET (7)                                 NULL,
    [UpdatedUTCDate]  DATETIME                                           NULL,
    [GST]             VARCHAR (100)                                      NULL,
    PRIMARY KEY CLUSTERED ([WrkCustomerID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_WrkImportFabrics_WrkImportFileID]
    ON [dbo].[WrkImportFabrics]([WrkImportFileID] ASC)
    INCLUDE([Title]) WITH (FILLFACTOR = 80);


GO

