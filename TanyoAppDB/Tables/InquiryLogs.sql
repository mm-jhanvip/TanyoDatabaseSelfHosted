CREATE TABLE [dbo].[InquiryLogs] (
    [InquiryLogId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [SentBy]         BIGINT             NOT NULL,
    [SalesmanId]     BIGINT             NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [InquiryId]      BIGINT             NOT NULL,
    PRIMARY KEY CLUSTERED ([InquiryLogId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_InquiryLogs_SentBy_SalesmanId]
    ON [dbo].[InquiryLogs]([SentBy] ASC, [SalesmanId] ASC)
    INCLUDE([CreatedBy]);


GO

