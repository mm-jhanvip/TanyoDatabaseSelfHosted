CREATE TABLE [dbo].[TenantContracts] (
    [TenantContractID] INT                IDENTITY (1, 1) NOT NULL,
    [TenantID]         INT                NOT NULL,
    [NosOfUsers]       INT                DEFAULT ((0)) NOT NULL,
    [NosOfAdmin]       INT                DEFAULT ((0)) NOT NULL,
    [PricePerSKU]      NUMERIC (18, 2)    NOT NULL,
    [OnBoardingDate]   DATE               NOT NULL,
    [LiveDate]         DATE               NOT NULL,
    [NextRenewAt]      DATE               NOT NULL,
    [Status]           INT                DEFAULT ((0)) NOT NULL,
    [LastUpdatedBy]    INT                NOT NULL,
    [LastUpdatedDate]  DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    PRIMARY KEY CLUSTERED ([TenantContractID] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_TenantContracts_TenantId]
    ON [dbo].[TenantContracts]([TenantID] ASC)
    INCLUDE([OnBoardingDate], [LiveDate], [NextRenewAt]);


GO

