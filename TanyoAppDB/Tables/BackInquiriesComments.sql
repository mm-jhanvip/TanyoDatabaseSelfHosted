CREATE TABLE [dbo].[BackInquiriesComments] (
    [BackInquiriesCommentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [BackInquiryId]          BIGINT             NOT NULL,
    [Comment]                NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]              INT                NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]         DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([BackInquiriesCommentId] ASC)
);


GO

