CREATE TABLE [dbo].[AuditLogs_20231027_1643] (
    [AuditLogId]     BIGINT             NOT NULL,
    [TableKey]       BIGINT             NOT NULL,
    [TableName]      VARCHAR (200)      NOT NULL,
    [FieldName]      VARCHAR (200)      NOT NULL,
    [CaptionName]    VARCHAR (200)      NOT NULL,
    [OldValue]       VARCHAR (MAX)      NULL,
    [NewValue]       VARCHAR (MAX)      NULL,
    [Actions]        VARCHAR (50)       NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate] DATETIME           NOT NULL
);


GO

