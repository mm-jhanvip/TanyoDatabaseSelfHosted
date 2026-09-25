CREATE TABLE [dbo].[Inquiries] (
    [InquiryId]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]         BIGINT             NOT NULL,
    [Inquiry]            NVARCHAR (MAX)     NOT NULL,
    [Source]             INT                NOT NULL,
    [Status]             INT                DEFAULT ((0)) NOT NULL,
    [SalesmanId]         BIGINT             NULL,
    [SalesmanAssignDate] DATE               NULL,
    [LastContactedDate]  DATE               NOT NULL,
    [CreatedBy]          BIGINT             NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          BIGINT             NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    [TenantId]           INT                NOT NULL,
    [Other]              VARCHAR (100)      NULL,
    PRIMARY KEY CLUSTERED ([InquiryId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_Inquiries_CustomerId]
    ON [dbo].[Inquiries]([CustomerId] ASC)
    INCLUDE([SalesmanId], [CreatedBy]);


GO

