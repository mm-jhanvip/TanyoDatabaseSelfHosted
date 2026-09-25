CREATE TABLE [dbo].[EmailCMSDetails] (
    [EmailCMSDetailID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [EmailCMSID]       BIGINT             NOT NULL,
    [EmailBody]        NVARCHAR (MAX)     NOT NULL,
    [TenantID]         BIGINT             NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF__EmailCMSD__Creat__5D80D6A1] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        BIGINT             NULL,
    [UpdatedDate]      DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]   DATETIME           NULL,
    [Subject]          VARCHAR (255)      NULL,
    PRIMARY KEY CLUSTERED ([EmailCMSDetailID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_EmailCMSDetails_EmailCMSID_TenantID]
    ON [dbo].[EmailCMSDetails]([EmailCMSID] ASC, [TenantID] ASC) WITH (FILLFACTOR = 70);


GO

