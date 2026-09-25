CREATE TABLE [dbo].[InvoiceFormat] (
    [InvoiceFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [FormatName]      NVARCHAR (100) NOT NULL,
    [TemplatePath]    NVARCHAR (500) NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_InvoiceFormat_IsDeleted] DEFAULT ((0)) NOT NULL,
    [DisplayOrder]    INT            CONSTRAINT [DF_InvoiceFormat_DisplayOrder] DEFAULT ((0)) NOT NULL,
    [IsLandscape]     BIT            CONSTRAINT [DF_InvoiceFormat_IsLandscape] DEFAULT ((0)) NOT NULL,
    [FormatType]      INT            CONSTRAINT [DF_InvoiceFormat_FormatType] DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InvoiceFormatId] ASC)
);


GO

