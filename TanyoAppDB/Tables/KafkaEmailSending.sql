CREATE TABLE [dbo].[KafkaEmailSending] (
    [KafkaEmailSendingId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]             BIGINT             NOT NULL,
    [Subject]             VARCHAR (MAX)      NULL,
    [TenantID]            BIGINT             NOT NULL,
    [CreatedBy]           INT                NOT NULL,
    [CreatedDate]         DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]      DATE               NOT NULL,
    [UpdatedBy]           INT                NULL,
    [UpdatedDate]         DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]      DATE               NULL,
    [EmailBody]           VARCHAR (MAX)      NULL,
    [OrderPdf]            VARCHAR (MAX)      NULL,
    [CustomerEmailId]     VARCHAR (250)      NULL,
    [NotificationEmail]   VARCHAR (250)      NULL,
    [AttachmentFileName]  VARCHAR (100)      NULL,
    CONSTRAINT [PK__OrderEma__69C8DBDC586F3433] PRIMARY KEY CLUSTERED ([KafkaEmailSendingId] ASC) WITH (FILLFACTOR = 80)
);


GO

