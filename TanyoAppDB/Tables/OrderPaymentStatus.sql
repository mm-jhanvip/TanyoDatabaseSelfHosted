CREATE TABLE [dbo].[OrderPaymentStatus] (
    [OrderPaymentStatusId] BIGINT       IDENTITY (1, 1) NOT NULL,
    [StatusEnumId]         INT          NULL,
    [Status]               VARCHAR (25) NULL,
    [StatusLabel]          VARCHAR (25) NULL,
    [Type]                 VARCHAR (50) NULL,
    CONSTRAINT [PK_PaymentStatusLabel] PRIMARY KEY CLUSTERED ([OrderPaymentStatusId] ASC)
);


GO

