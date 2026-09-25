CREATE TABLE [dbo].[TenantBankDetails] (
    [TenantBankDetailID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantID]           BIGINT             NOT NULL,
    [BankName]           VARCHAR (100)      NOT NULL,
    [AccountName]        VARCHAR (100)      NOT NULL,
    [AccountNo]          VARCHAR (50)       NOT NULL,
    [BranchName]         VARCHAR (100)      NOT NULL,
    [AccountType]        VARCHAR (50)       NOT NULL,
    [IFSCCode]           VARCHAR (20)       NOT NULL,
    [UPIId]              NVARCHAR (100)     NULL,
    [QRCode]             NVARCHAR (MAX)     NULL,
    [IsDeleted]          BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]          INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF__TenantBan__Creat__2C538F61] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          INT                NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    [LocationID]         BIGINT             NULL,
    PRIMARY KEY CLUSTERED ([TenantBankDetailID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_TenantBankDetails_TenantId_IsDeleted]
    ON [dbo].[TenantBankDetails]([TenantID] ASC, [IsDeleted] ASC);


GO

