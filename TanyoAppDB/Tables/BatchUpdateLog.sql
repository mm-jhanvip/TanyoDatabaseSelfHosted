CREATE TABLE [dbo].[BatchUpdateLog] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [TableName]     VARCHAR (100) NULL,
    [InsertedCount] INT           NULL,
    [DeletedCount]  INT           NULL,
    [RecordDate]    DATETIME      DEFAULT (getdate()) NULL,
    [TenantID]      INT           NULL,
    [OrderID]       INT           NULL
);


GO

