CREATE TABLE [dbo].[Comments] (
    [CommentId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [SubjectTypeId]  BIGINT             NOT NULL,
    [SubjectId]      BIGINT             NOT NULL,
    [Comment]        NVARCHAR (MAX)     NOT NULL,
    [Status]         INT                NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([CommentId] ASC)
);


GO

