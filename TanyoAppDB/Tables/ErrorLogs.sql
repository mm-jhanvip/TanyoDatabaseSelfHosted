CREATE TABLE [dbo].[ErrorLogs] (
    [ErrorLogId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [UserId]          INT                NULL,
    [TenantId]        INT                NULL,
    [RequestPath]     VARCHAR (250)      NULL,
    [ErrorMessage]    VARCHAR (MAX)      NULL,
    [ErrorException]  VARCHAR (MAX)      NULL,
    [ErrorStackTrace] VARCHAR (MAX)      NULL,
    [ErrorType]       VARCHAR (250)      NULL,
    [BrowserName]     VARCHAR (250)      NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__ErrorLogs__Creat__7E02B4CC] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ErrorLogId] ASC)
);


GO

