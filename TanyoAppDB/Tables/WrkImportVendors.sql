CREATE TABLE [dbo].[WrkImportVendors] (
    [WrkVendorID]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [WrkImportFileID]    BIGINT             NOT NULL,
    [VendorCode]         VARCHAR (MAX)      NULL,
    [VendorName]         VARCHAR (MAX)      NULL,
    [VendorEmailId]      VARCHAR (MAX)      NULL,
    [VendorPhone]        VARCHAR (MAX)      NULL,
    [GST]                VARCHAR (MAX)      NULL,
    [ContactPersonName]  VARCHAR (MAX)      NULL,
    [ContactPersonEmail] VARCHAR (MAX)      NULL,
    [ContactPersonPhone] VARCHAR (MAX)      NULL,
    [PaymentTermsInDays] VARCHAR (MAX)      NULL,
    [Status]             INT                NOT NULL,
    [ErrorMessage]       VARCHAR (MAX)      NULL,
    [CreatedBy]          BIGINT             NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF_WrkImportVendors_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           CONSTRAINT [DF_WrkImportVendors_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          BIGINT             NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    CONSTRAINT [PK_WrkImportVendors] PRIMARY KEY CLUSTERED ([WrkVendorID] ASC)
);


GO

