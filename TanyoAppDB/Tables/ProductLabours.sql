CREATE TABLE [dbo].[ProductLabours] (
    [ProductLabourId]         BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]               BIGINT             NOT NULL,
    [ManufacturingWorkFlowId] BIGINT             NOT NULL,
    [Amount]                  NUMERIC (18, 2)    CONSTRAINT [df_ProductLabours_Amount] DEFAULT ((0)) NOT NULL,
    [CreatedBy]               BIGINT             NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [IsDeleted]               BIT                DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductLabourId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ProductLabours_ProductId_ManufacturingWorkflowId]
    ON [dbo].[ProductLabours]([ProductId] ASC, [ManufacturingWorkFlowId] ASC) WITH (FILLFACTOR = 80);


GO

