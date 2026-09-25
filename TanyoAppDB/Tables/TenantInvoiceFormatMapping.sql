CREATE TABLE [dbo].[TenantInvoiceFormatMapping] (
    [TenantInvoiceFormatMappingId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]                     INT                NOT NULL,
    [InvoiceFormatId]              INT                NOT NULL,
    [TermsAndConditionsHtml]       NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]                    INT                NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]               DATETIME           NOT NULL,
    [UpdatedBy]                    INT                NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([TenantInvoiceFormatMappingId] ASC)
);


GO

