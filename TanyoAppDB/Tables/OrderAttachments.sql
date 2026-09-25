CREATE TABLE [dbo].[OrderAttachments] (
    [OrderAttachmentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]           BIGINT             NOT NULL,
    [FileType]          VARCHAR (10)       NOT NULL,
    [FileURL]           VARCHAR (MAX)      NOT NULL,
    [CreatedBy]         BIGINT             NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderAttachmentId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderAttachments_OrderId]
    ON [dbo].[OrderAttachments]([OrderId] ASC)
    INCLUDE([FileURL], [CreatedBy]) WITH (FILLFACTOR = 70);


GO

