CREATE TABLE [dbo].[LeadComments] (
    [LeadCommentId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [LeadId]         BIGINT             NOT NULL,
    [Comment]        NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LeadCommentId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_LeadComments__LeadId_CreatedBy]
    ON [dbo].[LeadComments]([LeadId] ASC, [CreatedBy] ASC) WITH (FILLFACTOR = 80);


GO

