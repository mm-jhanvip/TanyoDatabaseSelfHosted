CREATE TABLE [dbo].[TenantAPICount] (
    [Id]            INT    IDENTITY (1, 1) NOT NULL,
    [TenantId]      BIGINT NULL,
    [RequestsCount] BIGINT NULL,
    [Requestdate]   DATE   DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

