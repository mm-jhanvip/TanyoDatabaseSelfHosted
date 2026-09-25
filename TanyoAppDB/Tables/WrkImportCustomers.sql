CREATE TABLE [dbo].[WrkImportCustomers] (
    [WrkCustomerID]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [WrkImportFileID]        BIGINT             NOT NULL,
    [FirstName]              VARCHAR (MAX)      NULL,
    [LastName]               VARCHAR (MAX)      NULL,
    [PrimaryContactNumber]   VARCHAR (MAX)      NULL,
    [AlternateContactNumber] VARCHAR (MAX)      NULL,
    [EmailID]                VARCHAR (MAX)      NULL,
    [GSTNo]                  VARCHAR (MAX)      NULL,
    [Street1]                VARCHAR (MAX)      NULL,
    [Stree2]                 VARCHAR (MAX)      NULL,
    [Landmark]               VARCHAR (MAX)      NULL,
    [Area]                   VARCHAR (MAX)      NULL,
    [City]                   VARCHAR (MAX)      NULL,
    [State]                  VARCHAR (MAX)      NULL,
    [ZipCode]                VARCHAR (MAX)      NULL,
    [Status]                 INT                DEFAULT ((0)) NOT NULL,
    [ErrorMessage]           VARCHAR (MAX)      NULL,
    [CreatedBy]              BIGINT             NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) CONSTRAINT [DF__WrkImport__Creat__58F12BAE] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]         DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              BIGINT             NULL,
    [UpdatedDate]            DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    [Birthday]               VARCHAR (50)       NULL,
    [Profession]             VARCHAR (50)       NULL,
    [COMPANYNAME]            VARCHAR (50)       NULL,
    [AltName]                VARCHAR (50)       NULL,
    PRIMARY KEY CLUSTERED ([WrkCustomerID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_WrkImportCustomers_WrkImportFileID_Status]
    ON [dbo].[WrkImportCustomers]([WrkImportFileID] ASC, [Status] ASC) WITH (FILLFACTOR = 80);


GO

