CREATE TABLE [dbo].[ProductWareHouseQuantitiesLog] (
    [LogId]            INT                IDENTITY (1, 1) NOT NULL,
    [ProductId]        BIGINT             NOT NULL,
    [WareHouseID]      INT                NULL,
    [PreviousQuantity] DECIMAL (18, 2)    NULL,
    [NewQuantity]      DECIMAL (18, 2)    NULL,
    [Action]           VARCHAR (128)      NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_ProductWareHouseQuantitiesLog_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF_ProductWareHouseQuantitiesLog_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO

