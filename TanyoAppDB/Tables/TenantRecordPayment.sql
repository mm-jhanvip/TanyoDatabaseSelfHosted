CREATE TABLE [dbo].[TenantRecordPayment] (
    [TenantRecordPaymentId] INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]              INT                NOT NULL,
    [PaymentDate]           DATETIME           NOT NULL,
    [Amount]                DECIMAL (18, 2)    NULL,
    [CreatedDate]           DATETIMEOFFSET (7) NULL,
    [CreatedUTCDate]        DATETIME           NULL,
    [CreatedBy]             INT                NOT NULL,
    [Remarks]               NVARCHAR (200)     NULL,
    [UpdatedBy]             INT                NULL,
    [UpdatedDate]           DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]        DATETIME           NULL,
    [IsDeleted]             BIT                CONSTRAINT [D_TenantRecordPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UpcomingDueDate]       DATETIME           NULL,
    [RazorpayPaymentId]     VARCHAR (200)      NULL,
    [RazorpayLinkId]        VARCHAR (200)      NULL,
    [RecurringCharges]      DECIMAL (18, 2)    NULL,
    CONSTRAINT [PK_TenantRecordPayment] PRIMARY KEY CLUSTERED ([TenantRecordPaymentId] ASC)
);


GO

