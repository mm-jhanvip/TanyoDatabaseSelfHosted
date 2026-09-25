CREATE TABLE [dbo].[tanyo_user_mcp] (
    [UserId]     INT            IDENTITY (1, 1) NOT NULL,
    [TenantId]   INT            NOT NULL,
    [TenantName] NVARCHAR (100) NOT NULL,
    [Username]   NVARCHAR (100) NOT NULL,
    [Password]   NVARCHAR (255) NOT NULL,
    PRIMARY KEY CLUSTERED ([UserId] ASC),
    UNIQUE NONCLUSTERED ([Username] ASC)
);


GO

