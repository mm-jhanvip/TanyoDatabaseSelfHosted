CREATE TABLE [dbo].[DailyStockValuation] (
    [DailyStockValuationId]     BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]                 BIGINT             NOT NULL,
    [ImagePath]                 VARCHAR (MAX)      NULL,
    [ModelNo]                   VARCHAR (100)      NOT NULL,
    [ProductTitle]              VARCHAR (150)      NOT NULL,
    [ActualStock]               NUMERIC (18, 2)    NULL,
    [CategoryId]                BIGINT             NOT NULL,
    [CategoryName]              VARCHAR (150)      NOT NULL,
    [ValuationOfActualStock]    NUMERIC (18, 2)    NULL,
    [ValuationOfRetailStock]    NUMERIC (18, 2)    NULL,
    [ValuationOfWholesaleStock] NUMERIC (18, 2)    NULL,
    [CreatedDate]               DATETIMEOFFSET (7) CONSTRAINT [DF_DailyStockValuation_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [ReportDate]                DATETIMEOFFSET (7) CONSTRAINT [DF_DailyStockValuation_ReportDate] DEFAULT (dateadd(day,(-1),sysdatetimeoffset())) NOT NULL,
    PRIMARY KEY CLUSTERED ([DailyStockValuationId] ASC)
);


GO

