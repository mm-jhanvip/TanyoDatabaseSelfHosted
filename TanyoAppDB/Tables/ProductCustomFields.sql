CREATE TABLE [dbo].[ProductCustomFields] (
    [Id]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]      BIGINT             NOT NULL,
    [LookupValueId]  INT                NOT NULL,
    [CustomValue]    NVARCHAR (255)     NOT NULL,
    [TenantId]       INT                NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

CREATE NONCLUSTERED INDEX [ix_ProductCustomFields_cover]
    ON [dbo].[ProductCustomFields]([ProductId] ASC, [TenantId] ASC)
    INCLUDE([LookupValueId], [CustomValue]) WITH (FILLFACTOR = 70);


GO

