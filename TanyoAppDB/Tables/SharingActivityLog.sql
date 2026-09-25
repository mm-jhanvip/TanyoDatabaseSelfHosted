CREATE TABLE [dbo].[SharingActivityLog] (
    [ID]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [SubjectTypeId]  INT                NOT NULL,
    [SubjectId]      BIGINT             NOT NULL,
    [Description]    VARCHAR (500)      NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

