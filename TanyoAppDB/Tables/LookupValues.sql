CREATE TABLE [dbo].[LookupValues] (
    [LookupValueId]   INT                IDENTITY (1, 1) NOT NULL,
    [LookupId]        INT                NOT NULL,
    [LookupValueName] NVARCHAR (250)     NULL,
    [IsDeleted]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__LookupVal__Creat__078C1F06] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [IsVisible]       BIT                DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([LookupValueId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_LookupValues_LookupId_IsDeleted]
    ON [dbo].[LookupValues]([LookupId] ASC, [IsDeleted] ASC)
    INCLUDE([LookupValueName], [CreatedBy]) WITH (FILLFACTOR = 80);


GO

