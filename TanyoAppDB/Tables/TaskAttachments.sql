CREATE TABLE [dbo].[TaskAttachments] (
    [TaskAttachmentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TaskId]           BIGINT             NOT NULL,
    [FileName]         VARCHAR (150)      NOT NULL,
    [AttachmentURL]    VARCHAR (MAX)      NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([TaskAttachmentId] ASC)
);


GO

