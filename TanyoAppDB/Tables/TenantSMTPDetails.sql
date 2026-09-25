CREATE TABLE [dbo].[TenantSMTPDetails] (
    [TenantSMTPDetailId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantID]           BIGINT             NOT NULL,
    [FromEmail]          VARCHAR (100)      NOT NULL,
    [Username]           VARCHAR (100)      NOT NULL,
    [Password]           VARCHAR (100)      NOT NULL,
    [SMTPServer]         VARCHAR (100)      NOT NULL,
    [SMTPPort]           INT                NOT NULL,
    [EnableSSL]          BIT                NOT NULL,
    [IsDeleted]          BIT                CONSTRAINT [DF__TenantSMT__IsDel__06ED0088] DEFAULT ((0)) NOT NULL,
    [CreatedBy]          INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF__TenantSMT__Creat__07E124C1] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           CONSTRAINT [DF__TenantSMT__Creat__08D548FA] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          INT                NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    [TargetName]         VARCHAR (100)      NULL,
    CONSTRAINT [PK__TenantSM__1805E29B768EE60E] PRIMARY KEY CLUSTERED ([TenantSMTPDetailId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_TenantSMTPDetails_TenantId_IsDeleted_CreatedBy]
    ON [dbo].[TenantSMTPDetails]([TenantID] ASC, [IsDeleted] ASC, [CreatedBy] ASC);


GO

