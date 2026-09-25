CREATE TABLE [dbo].[OrderShortedURL] (
    [OrderShortedURLId] INT                IDENTITY (1, 1) NOT NULL,
    [OriginalURL]       NVARCHAR (MAX)     NULL,
    [ShortedURL]        NVARCHAR (50)      NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NULL,
    [CreatedUTCDate]    DATETIME           NULL,
    [OrderId]           BIGINT             NULL
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderShortedURL_OrderId]
    ON [dbo].[OrderShortedURL]([OrderId] ASC)
    INCLUDE([ShortedURL], [CreatedDate]) WITH (FILLFACTOR = 70);


GO

