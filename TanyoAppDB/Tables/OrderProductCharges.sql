CREATE TABLE [dbo].[OrderProductCharges] (
    [OrderProductChargeId] BIGINT                                               IDENTITY (1, 1) NOT NULL,
    [OrderId]              BIGINT                                               NOT NULL,
    [OrderSetItemId]       BIGINT                                               NOT NULL,
    [EntityTypeId]         BIGINT                                               NOT NULL,
    [EntityId]             BIGINT                                               NOT NULL,
    [Price]                NUMERIC (18, 2) CONSTRAINT [df_OrderProductCharges_Price] DEFAULT ((0)) NOT NULL,
    [CreatedBy]            BIGINT                                               NOT NULL,
    [CreatedDate]          DATETIMEOFFSET (7)                                   DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]       DATETIME                                             DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderProductChargeId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderProductCharges_OrderSetItemId_EntityTypeId_EntityId]
    ON [dbo].[OrderProductCharges]([OrderId] ASC, [OrderSetItemId] ASC, [EntityTypeId] ASC, [EntityId] ASC) WITH (FILLFACTOR = 80);


GO

