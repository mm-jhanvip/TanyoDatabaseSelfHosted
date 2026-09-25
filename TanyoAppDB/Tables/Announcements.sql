CREATE TABLE [dbo].[Announcements] (
    [AnnouncementId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [Message]        NVARCHAR (MAX)     NOT NULL,
    [TenantId]       BIGINT             NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([AnnouncementId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_Announcements_cover]
    ON [dbo].[Announcements]([TenantId] ASC)
    INCLUDE([AnnouncementId], [Message]) WITH (FILLFACTOR = 70);


GO

