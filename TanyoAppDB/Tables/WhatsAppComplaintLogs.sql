CREATE TABLE [dbo].[WhatsAppComplaintLogs] (
    [WhatsAppComplaintLogId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [MobileNo]               VARCHAR (20)       NOT NULL,
    [CustomerId]             BIGINT             NOT NULL,
    [OrderId]                BIGINT             NULL,
    [OrderSetItemId]         BIGINT             NULL,
    [Description]            VARCHAR (MAX)      NULL,
    [ImageURL]               VARCHAR (MAX)      NULL,
    [Status]                 BIT                DEFAULT ((0)) NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]         DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdateDate]             DATETIME           NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([WhatsAppComplaintLogId] ASC)
);


GO

