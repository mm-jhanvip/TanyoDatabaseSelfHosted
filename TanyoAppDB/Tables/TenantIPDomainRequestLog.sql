CREATE TABLE [dbo].[TenantIPDomainRequestLog] (
    [Id]             INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NULL,
    [RequestIP]      VARCHAR (50)       NULL,
    [RequestUrl]     VARCHAR (1000)     NULL,
    [RequestDomain]  VARCHAR (100)      NULL,
    [UserAgent]      VARCHAR (MAX)      NULL,
    [IsAuthorized]   BIT                NULL,
    [FailureReason]  VARCHAR (500)      NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_TenIDWhiteLog_Created] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_TenIDWhiteLog_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

