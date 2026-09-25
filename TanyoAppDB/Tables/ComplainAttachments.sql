CREATE TABLE [dbo].[ComplainAttachments] (
    [ComplainImageId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ComplainId]      BIGINT             NOT NULL,
    [CommentId]       BIGINT             NULL,
    [ImagePath]       VARCHAR (MAX)      NOT NULL,
    [ImageType]       INT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       BIGINT             NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK__Complain__8E0DB15715DEED69] PRIMARY KEY CLUSTERED ([ComplainImageId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_ComplainAttachments_ComplainId_CommentId]
    ON [dbo].[ComplainAttachments]([ComplainId] ASC, [CommentId] ASC)
    INCLUDE([ImagePath], [CreatedBy]);


GO

