CREATE TABLE [dbo].[ManufacturingWorkflowStock] (
    [Id]                      BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]               BIGINT             NOT NULL,
    [ManufacturingWorkflowId] BIGINT             NOT NULL,
    [StockQty]                INT                NOT NULL,
    [CreatedBy]               BIGINT             NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               BIGINT             NULL,
    [UpdatedDate]             DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]          DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

