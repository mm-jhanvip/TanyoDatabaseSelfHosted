CREATE TABLE [dbo].[TenantReminderSettings] (
    [TenantReminderSettingId] INT                IDENTITY (1, 1) NOT NULL,
    [ReminderType]            VARCHAR (50)       NOT NULL,
    [ReminderDays]            INT                NOT NULL,
    [CreatedBy]               BIGINT             NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [Position]                INT                NOT NULL,
    [TenantId]                INT                NOT NULL,
    PRIMARY KEY CLUSTERED ([TenantReminderSettingId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_TenantReminderSettings_TenantId_ReminderDays]
    ON [dbo].[TenantReminderSettings]([TenantId] ASC, [ReminderDays] ASC);


GO

