CREATE TABLE [dbo].[ProductShareBatchDetail] (
    [Id]              BIGINT                                               IDENTITY (1, 1) NOT NULL,
    [BatchId]         BIGINT                                               NOT NULL,
    [TenantId]        BIGINT                                               NOT NULL,
    [ProductId]       BIGINT                                               NOT NULL,
    [WholesalerPrice] NUMERIC (18, 2) NOT NULL,
    [CustomerId]      BIGINT                                               NOT NULL,
    [TagId]           BIGINT                                               NULL,
    [ToTenantId]      BIGINT                                               NULL,
    [Status]          INT                                                  DEFAULT ((0)) NOT NULL,
    [CreatedBy]       BIGINT                                               NOT NULL,
    [CreatedDate]     DATETIME                                             DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate]  DATETIME                                             DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       BIGINT                                               NULL,
    [UpdatedDate]     DATETIME                                             NULL,
    [UpdatedUTCDate]  DATETIME                                             NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

