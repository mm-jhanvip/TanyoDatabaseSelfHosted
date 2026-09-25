CREATE TABLE [dbo].[AuditLogs] (
    [AuditLogId]     BIGINT             IDENTITY (1, 1) NOT NULL,
    [TableKey]       BIGINT             NOT NULL,
    [TableName]      VARCHAR (200)      NOT NULL,
    [FieldName]      VARCHAR (200)      NOT NULL,
    [CaptionName]    VARCHAR (200)      NOT NULL,
    [OldValue]       VARCHAR (MAX)      NULL,
    [NewValue]       VARCHAR (MAX)      NULL,
    [Actions]        VARCHAR (50)       NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([AuditLogId] ASC)
);


GO

