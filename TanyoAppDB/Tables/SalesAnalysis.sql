CREATE TABLE [dbo].[SalesAnalysis] (
    [SalesAnalysisId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Date]            DATE          NOT NULL,
    [TenantID]        INT           NOT NULL,
    [TenantName]      VARCHAR (500) NOT NULL,
    [SalesmanName]    VARCHAR (500) NULL,
    [CustomerName]    VARCHAR (500) NOT NULL,
    [ProductName]     VARCHAR (500) NOT NULL,
    [Quantity]        INT           NOT NULL,
    [Amount]          BIGINT        NOT NULL,
    [OrderStatus]     VARCHAR (150) NOT NULL,
    PRIMARY KEY CLUSTERED ([SalesAnalysisId] ASC)
);


GO

