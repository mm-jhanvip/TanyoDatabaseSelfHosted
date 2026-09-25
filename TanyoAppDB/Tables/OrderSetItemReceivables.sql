CREATE TABLE [dbo].[OrderSetItemReceivables] (
    [OrderSetItemReceivableId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderSetItemId]           BIGINT             NOT NULL,
    [ReceivedDate]             DATETIMEOFFSET (7) NOT NULL,
    [ProvidedMaterial]         NUMERIC (5, 2)     NOT NULL,
    [ReceivedFrom]             VARCHAR (50)       NOT NULL,
    [ReceivedBy]               BIGINT             NOT NULL,
    [Comment]                  NVARCHAR (MAX)     NULL,
    [CreatedBy]                BIGINT             NOT NULL,
    [CreatedDate]              DATETIMEOFFSET (7) CONSTRAINT [DF__OrderSetI__Creat__46D27B73] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]           DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                BIGINT             NULL,
    [UpdatedDate]              DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]           DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([OrderSetItemReceivableId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderSetItemReceivables_OrderSetItemId]
    ON [dbo].[OrderSetItemReceivables]([OrderSetItemId] ASC)
    INCLUDE([ReceivedBy]);


GO

