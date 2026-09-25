CREATE TABLE [dbo].[ProductQuantitiesLog] (
    [LogId]            INT                IDENTITY (1, 1) NOT NULL,
    [ProductId]        BIGINT             NOT NULL,
    [PreviousQuantity] DECIMAL (18, 2)    NULL,
    [NewQuantity]      DECIMAL (18, 2)    NULL,
    [Action]           VARCHAR (128)      NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_ProductQuantitiesLog_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           CONSTRAINT [DF_ProductQuantitiesLog_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO

