CREATE TABLE [dbo].[WrkInwardProducts] (
    [WrkInwardProductID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [WrkImportFileID]    BIGINT             NOT NULL,
    [CategoryName]       VARCHAR (MAX)      NULL,
    [ProductTitle]       VARCHAR (MAX)      NULL,
    [ModelNo]            VARCHAR (MAX)      NULL,
    [StockQty]           VARCHAR (MAX)      NULL,
    [VendorName]         VARCHAR (MAX)      NULL,
    [WarehouseName]      VARCHAR (MAX)      NULL,
    [Status]             INT                CONSTRAINT [DF_WrkInwardProducts_Status] DEFAULT ((0)) NOT NULL,
    [ErrorMessage]       VARCHAR (MAX)      NULL,
    [CreatedBy]          BIGINT             NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF_WrkInwardProducts_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           CONSTRAINT [DF_WrkInwardProducts_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          BIGINT             NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([WrkInwardProductID] ASC)
);


GO

