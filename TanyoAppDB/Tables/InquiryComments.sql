CREATE TABLE [dbo].[InquiryComments] (
    [InquiryCommentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [InquiryId]        BIGINT             NOT NULL,
    [Comment]          NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([InquiryCommentId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_InquiryComments_InquiryId_CreatedBy]
    ON [dbo].[InquiryComments]([InquiryId] ASC, [CreatedBy] ASC);


GO

