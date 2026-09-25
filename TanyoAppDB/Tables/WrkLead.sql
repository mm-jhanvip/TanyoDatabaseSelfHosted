CREATE TABLE [dbo].[WrkLead] (
    [WrkLeadId]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [WrkImportFileID]  INT                NULL,
    [TenantId]         INT                NOT NULL,
    [CustomerName]     VARCHAR (MAX)      NULL,
    [PhoneNumber]      VARCHAR (MAX)      NULL,
    [Address]          VARCHAR (MAX)      NULL,
    [LeadStatus]       VARCHAR (MAX)      NULL,
    [SalesmanName]     VARCHAR (MAX)      NULL,
    [LeadSource]       VARCHAR (MAX)      NULL,
    [InquiryFor]       VARCHAR (MAX)      NULL,
    [PurchaseUrgency]  VARCHAR (MAX)      NULL,
    [CustomerBehavior] VARCHAR (MAX)      NULL,
    [Notes]            VARCHAR (MAX)      NULL,
    [ErrorMessage]     VARCHAR (MAX)      NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_WrkLead_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF_WrkLead_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        BIGINT             NULL,
    [UpdatedDate]      DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]   DATETIME           NULL,
    [Status]           INT                DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WrkLead] PRIMARY KEY CLUSTERED ([WrkLeadId] ASC)
);


GO

