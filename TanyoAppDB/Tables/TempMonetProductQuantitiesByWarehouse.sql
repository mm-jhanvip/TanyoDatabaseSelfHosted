CREATE TABLE [dbo].[TempMonetProductQuantitiesByWarehouse] (
    [ProductId]    BIGINT          NOT NULL,
    [ProductTitle] VARCHAR (150)   NOT NULL,
    [ModelNo]      VARCHAR (27)    NOT NULL,
    [ColumnName]   NVARCHAR (128)  NULL,
    [Qty]          INT             NOT NULL,
    [WarehouseId]  BIGINT          NULL,
    [Quantity]     NUMERIC (18, 2) NULL
);


GO

