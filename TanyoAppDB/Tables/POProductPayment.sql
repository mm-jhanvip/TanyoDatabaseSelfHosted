CREATE TABLE [dbo].[POProductPayment] (
    [POProductPaymentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [POProductId]        BIGINT             NOT NULL,
    [VendorId]           BIGINT             NOT NULL,
    [TenantId]           INT                NOT NULL,
    [PaymentType]        INT                CONSTRAINT [DF_POProductPayment_PaymentType] DEFAULT ((0)) NOT NULL,
    [PaymentStatus]      INT                CONSTRAINT [DF_POProductPayment_PaymentStatus] DEFAULT ((0)) NOT NULL,
    [BankName]           VARCHAR (100)      NULL,
    [AccountHolderName]  VARCHAR (100)      NULL,
    [ChequeNo]           VARCHAR (50)       NULL,
    [ReceivedAmount]     NUMERIC (18, 2)    NULL,
    [PaymentReceivedBy]  INT                NULL,
    [ReceivedDate]       DATETIME           CONSTRAINT [DF_POProductPayment_ReceivedDate] DEFAULT (getdate()) NOT NULL,
    [PaymentApprovedBy]  INT                NULL,
    [ApprovedDate]       DATETIMEOFFSET (7) NULL,
    [Comments]           VARCHAR (MAX)      NULL,
    [TransactionId]      VARCHAR (100)      NULL,
    [IsDeleted]          BIT                CONSTRAINT [DF_POProductPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]          INT                NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF_POProductPayment_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     SMALLDATETIME      CONSTRAINT [DF_POProductPayment_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          INT                NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     SMALLDATETIME      NULL,
    PRIMARY KEY CLUSTERED ([POProductPaymentId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_POProductPayment_Cover]
    ON [dbo].[POProductPayment]([POProductId] ASC, [VendorId] ASC, [TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([PaymentType], [PaymentStatus], [BankName], [AccountHolderName], [ChequeNo], [ReceivedAmount], [PaymentReceivedBy], [ReceivedDate], [Comments]);


GO

