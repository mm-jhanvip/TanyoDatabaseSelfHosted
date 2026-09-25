CREATE TABLE [dbo].[FeedbackComments] (
    [FeedbackCommentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]           BIGINT             NOT NULL,
    [Comment]           VARCHAR (500)      NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]    DATETIME           NOT NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    CONSTRAINT [PK__Feedback__5A88CF6DB41D9FA7] PRIMARY KEY CLUSTERED ([FeedbackCommentId] ASC)
);


GO

