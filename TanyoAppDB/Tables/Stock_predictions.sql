CREATE TABLE [dbo].[Stock_predictions] (
    [tenant_id]               INT           NOT NULL,
    [product_name]            VARCHAR (255) NOT NULL,
    [base_performance]        FLOAT (53)    NOT NULL,
    [performance_percentage]  FLOAT (53)    NOT NULL,
    [performance_category]    VARCHAR (50)  NOT NULL,
    [days_to_sell]            INT           NOT NULL,
    [number_of_stock]         FLOAT (53)    NOT NULL,
    [remaining_stock]         FLOAT (53)    NOT NULL,
    [remaining_stock_penalty] FLOAT (53)    NOT NULL,
    [sold_stock]              FLOAT (53)    NOT NULL,
    [purchase_price]          FLOAT (53)    NOT NULL,
    [selling_price]           FLOAT (53)    NOT NULL,
    [profit_margin]           FLOAT (53)    NOT NULL,
    [stock_turnover_ratio]    FLOAT (53)    NOT NULL,
    [turnover_rate]           FLOAT (53)    NOT NULL,
    [stock_efficiency]        FLOAT (53)    NOT NULL,
    [stock_age_penalty]       FLOAT (53)    NOT NULL,
    [record_date]             DATE          DEFAULT (getdate()) NOT NULL,
    [product_id]              INT           NULL
);


GO

