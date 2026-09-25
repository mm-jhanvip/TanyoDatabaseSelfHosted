CREATE TABLE [dbo].[RecurringPaymentRecords] (
    [PaymentLinkId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NOT NULL,
    [RazorpayLinkId] NVARCHAR (100)     NOT NULL,
    [Type]           INT                NOT NULL,
    [Amount]         DECIMAL (18, 2)    NOT NULL,
    [Status]         NVARCHAR (50)      NOT NULL,
    [PaymentURL]     NVARCHAR (500)     NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate] DATETIME           NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK_RecurringPaymentRecords] PRIMARY KEY CLUSTERED ([PaymentLinkId] ASC)
);


GO

