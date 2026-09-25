CREATE TABLE [dbo].[ProductShareBatch] (
    [Id]             BIGINT       IDENTITY (1, 1) NOT NULL,
    [BatchNo]        VARCHAR (50) NOT NULL,
    [Title]          VARCHAR (50) NULL,
    [TenantId]       BIGINT       NOT NULL,
    [CreatedBy]      BIGINT       NOT NULL,
    [CreatedDate]    DATETIME     DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate] DATETIME     DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT       NULL,
    [UpdatedDate]    DATETIME     NULL,
    [UpdatedUTCDate] DATETIME     NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

