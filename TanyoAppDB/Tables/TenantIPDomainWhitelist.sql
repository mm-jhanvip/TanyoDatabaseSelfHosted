CREATE TABLE [dbo].[TenantIPDomainWhitelist] (
    [Id]             INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NOT NULL,
    [SecretKey]      VARCHAR (100)      NOT NULL,
    [IPorDoaminName] VARCHAR (500)      NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_TeIDWhiteList_Created] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_TeIDWhiteList_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

