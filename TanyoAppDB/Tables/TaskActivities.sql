CREATE TABLE [dbo].[TaskActivities] (
    [TaskActivityId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TaskId]         BIGINT             NOT NULL,
    [Description]    VARCHAR (MAX)      NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([TaskActivityId] ASC)
);


GO

