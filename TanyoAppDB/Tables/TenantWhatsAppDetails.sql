CREATE TABLE [dbo].[TenantWhatsAppDetails] (
    [TenantWhatsAppDetailID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantID]               BIGINT             NOT NULL,
    [BaseURL]                VARCHAR (50)       NOT NULL,
    [APIVersion]             VARCHAR (50)       NOT NULL,
    [PhoneNumberID]          VARCHAR (50)       NOT NULL,
    [BusinessAccountID]      VARCHAR (50)       CONSTRAINT [DF_TenantWhatsAppDetails_BusinessAccountID] DEFAULT ('') NULL,
    [AppID]                  VARCHAR (20)       CONSTRAINT [DF_TenantWhatsAppDetails_AppID] DEFAULT ('') NULL,
    [AccessToken]            VARCHAR (MAX)      NOT NULL,
    [IsDeleted]              BIT                CONSTRAINT [DF__TenantWha__IsDel__673F4B05] DEFAULT ((0)) NOT NULL,
    [CreatedBy]              BIGINT             NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) CONSTRAINT [DF__TenantWha__Creat__68336F3E] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]         DATETIME           CONSTRAINT [DF__TenantWha__Creat__69279377] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              BIGINT             NULL,
    [UpdatedDate]            DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    CONSTRAINT [PK__TenantWh__A1D4F53959DA346A] PRIMARY KEY CLUSTERED ([TenantWhatsAppDetailID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_TenantWhatsAppDetails_TenantId_IsDeleted]
    ON [dbo].[TenantWhatsAppDetails]([TenantID] ASC, [IsDeleted] ASC)
    INCLUDE([AccessToken], [CreatedDate]);


GO

