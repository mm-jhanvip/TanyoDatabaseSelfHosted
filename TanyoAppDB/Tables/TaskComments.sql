CREATE TABLE [dbo].[TaskComments] (
    [TaskCommentId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [TaskId]         BIGINT             NOT NULL,
    [Description]    VARCHAR (MAX)      NOT NULL,
    [Hours]          VARCHAR (10)       NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([TaskCommentId] ASC)
);


GO

