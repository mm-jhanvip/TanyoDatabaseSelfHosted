CREATE TABLE [dbo].[CustomerVisits] (
    [CustomerVisitId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]      BIGINT             NOT NULL,
    [Comment]         NVARCHAR (1000)    NULL,
    [CreatedBy]       BIGINT             NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__CustomerV__Creat__6A1BB7B0] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NULL,
    [CategoryId]      BIGINT             NULL,
    [LocationID]      BIGINT             NULL,
    PRIMARY KEY CLUSTERED ([CustomerVisitId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_CustomerVisits_CustomerId_CreatedBy]
    ON [dbo].[CustomerVisits]([CustomerId] ASC, [CreatedBy] ASC) WITH (FILLFACTOR = 80);


GO

