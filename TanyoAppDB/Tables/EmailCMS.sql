CREATE TABLE [dbo].[EmailCMS] (
    [EmailCMSID]     BIGINT             IDENTITY (1, 1) NOT NULL,
    [KeyName]        VARCHAR (50)       NOT NULL,
    [TenantID]       BIGINT             NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__EmailCMS__Create__59B045BD] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([EmailCMSID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_EmailCMS_TenantID_CreatedBy]
    ON [dbo].[EmailCMS]([TenantID] ASC, [CreatedBy] ASC) WITH (FILLFACTOR = 70);


GO

