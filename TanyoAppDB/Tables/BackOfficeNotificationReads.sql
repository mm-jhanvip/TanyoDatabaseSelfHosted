CREATE TABLE [dbo].[BackOfficeNotificationReads] (
    [BackOfficeNotificationReadsId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [NotificationId]                BIGINT             NOT NULL,
    [UserID]                        BIGINT             NOT NULL,
    [IsRead]                        BIT                DEFAULT ((1)) NOT NULL,
    [ReadDate]                      DATETIMEOFFSET (7) NOT NULL,
    [CreatedBy]                     BIGINT             NOT NULL,
    [CreatedDate]                   DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     BIGINT             NULL,
    [UpdatedDate]                   DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]                DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([BackOfficeNotificationReadsId] ASC)
);


GO

