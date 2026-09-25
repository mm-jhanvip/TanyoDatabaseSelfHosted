CREATE TABLE [dbo].[PaymentRazorPay] (
    [PaymentRazorPayId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [PaymentOrderId]    VARCHAR (100)      NOT NULL,
    [TanyoOrderId]      BIGINT             NOT NULL,
    [SignatureKey]      VARCHAR (500)      NULL,
    [PaymentId]         VARCHAR (100)      NULL,
    [PaymentStatus]     VARCHAR (50)       NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]    DATETIME           NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    [UpdatedBy]         INT                NULL,
    [TenantId]          INT                NOT NULL,
    CONSTRAINT [PK_PaymentRazorPay] PRIMARY KEY CLUSTERED ([PaymentRazorPayId] ASC)
);


GO

