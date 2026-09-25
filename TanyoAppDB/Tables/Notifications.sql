CREATE TABLE [dbo].[Notifications] (
    [NotificationId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [EntityTypeId]     BIGINT             NOT NULL,
    [EntityId]         BIGINT             NOT NULL,
    [NotificationType] VARCHAR (50)       NOT NULL,
    [Message]          VARCHAR (500)      NULL,
    [IsRead]           BIT                DEFAULT ((0)) NOT NULL,
    [SentTo]           BIGINT             NOT NULL,
    [SentBy]           BIGINT             NOT NULL,
    [TenantId]         BIGINT             NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [ApplicationType]  INT                NULL,
    [IsAccessible]     BIT                DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([NotificationId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Notifications_SentTo_TenantId_CreatedUTCDate]
    ON [dbo].[Notifications]([SentTo] ASC, [TenantId] ASC, [CreatedUTCDate] ASC)
    INCLUDE([EntityTypeId], [EntityId], [NotificationType], [Message], [IsRead], [SentBy], [CreatedDate]) WITH (FILLFACTOR = 80);


GO

