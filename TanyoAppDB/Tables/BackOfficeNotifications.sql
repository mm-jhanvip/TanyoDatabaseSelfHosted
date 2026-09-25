CREATE TABLE [dbo].[BackOfficeNotifications] (
    [NotificationId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [ShortMessage]        NVARCHAR (200)     NOT NULL,
    [Message]             NVARCHAR (MAX)     NULL,
    [IsActive]            BIT                DEFAULT ((1)) NOT NULL,
    [CreatedBy]           BIGINT             NOT NULL,
    [CreatedDate]         DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]      DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           BIGINT             NULL,
    [UpdatedDate]         DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]      DATETIME           NULL,
    [VersionNumber]       VARCHAR (10)       NULL,
    [ReleaseDate]         DATE               NULL,
    [ApplicationPlatform] VARCHAR (10)       NULL,
    PRIMARY KEY CLUSTERED ([NotificationId] ASC)
);


GO

