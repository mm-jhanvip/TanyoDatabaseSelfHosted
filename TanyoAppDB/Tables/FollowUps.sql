CREATE TABLE [dbo].[FollowUps] (
    [FollowUpId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [SubjectTypeId]   BIGINT             NOT NULL,
    [SubjectId]       BIGINT             NOT NULL,
    [FollowUpComment] NVARCHAR (MAX)     NOT NULL,
    [FollowUpDate]    DATETIME           NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([FollowUpId] ASC)
);


GO

