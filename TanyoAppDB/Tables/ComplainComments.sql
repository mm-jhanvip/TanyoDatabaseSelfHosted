CREATE TABLE [dbo].[ComplainComments] (
    [ComplainCommentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ComplainId]        BIGINT             NOT NULL,
    [Comment]           VARCHAR (MAX)      NOT NULL,
    [CreatedBy]         BIGINT             NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK__Complain__0A278136B1C790B4] PRIMARY KEY CLUSTERED ([ComplainCommentId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ComplainComments_ComplainId_CreatedBy]
    ON [dbo].[ComplainComments]([ComplainId] ASC, [CreatedBy] ASC);


GO

