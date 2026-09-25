CREATE TABLE [dbo].[TenantModulePermissions] (
    [Id]         INT            IDENTITY (1, 1) NOT NULL,
    [ModuleName] NVARCHAR (50)  NOT NULL,
    [TenantId]   INT            NOT NULL,
    [ClaimType]  NVARCHAR (50)  NOT NULL,
    [ClaimValue] NVARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_TenantModulePermissions] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 80)
);


GO

