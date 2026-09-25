CREATE TABLE [dbo].[Lookups] (
    [LookupId]       INT                IDENTITY (1, 1) NOT NULL,
    [LookupName]     VARCHAR (50)       NOT NULL,
    [TenantId]       INT                NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF__Lookups__IsDelet__671F4F74] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Lookups__Created__681373AD] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__Lookups__Created__690797E6] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK__Lookups__6D8B9C4B86445E33] PRIMARY KEY CLUSTERED ([LookupId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Lookups_TenantId_IsDeleted]
    ON [dbo].[Lookups]([TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([LookupName], [CreatedBy]) WITH (FILLFACTOR = 70);


GO

