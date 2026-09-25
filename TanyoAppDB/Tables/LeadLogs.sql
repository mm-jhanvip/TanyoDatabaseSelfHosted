CREATE TABLE [dbo].[LeadLogs] (
    [LeadLogId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [LeadId]         BIGINT             NOT NULL,
    [SentBy]         BIGINT             NOT NULL,
    [SalesmanId]     BIGINT             NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LeadLogId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_LeadLogs_CreatedDate]
    ON [dbo].[LeadLogs]([CreatedDate] ASC)
    INCLUDE([LeadId]) WITH (FILLFACTOR = 80);


GO

