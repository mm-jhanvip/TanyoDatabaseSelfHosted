CREATE TABLE [dbo].[TagType] (
    [TagTypeId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [TagTypeName]    VARCHAR (10)       NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF__TagType__IsDelet__04C58C4B] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__TagType__Created__05B9B084] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__TagType__Created__06ADD4BD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    [TenantId]       INT                NOT NULL,
    CONSTRAINT [PK__TagType__BEE8EF2BFF7D73BC] PRIMARY KEY CLUSTERED ([TagTypeId] ASC) WITH (FILLFACTOR = 80)
);


GO

