CREATE TABLE [dbo].[TenantInfo] (
    [TenantInfoId]     INT            IDENTITY (1, 1) NOT NULL,
    [OrganizationType] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_TenantInfo] PRIMARY KEY CLUSTERED ([TenantInfoId] ASC)
);


GO

