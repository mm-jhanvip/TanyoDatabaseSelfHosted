CREATE TABLE [dbo].[ManufacturingActivityLogs] (
    [ManufacturingActivityLogID]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderManufacturingWorkflowId] BIGINT             NOT NULL,
    [Description]                  VARCHAR (500)      NULL,
    [Action]                       VARCHAR (10)       NOT NULL,
    [ManufacturingWorkflowId]      INT                NOT NULL,
    [ProductId]                    BIGINT             NOT NULL,
    [CreatedBy]                    INT                NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NULL,
    [CreatedUTCDate]               DATETIME           DEFAULT (getutcdate()) NULL,
    PRIMARY KEY CLUSTERED ([ManufacturingActivityLogID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ManufacturingActivityLogs_OrderManufacturingWorkflowId]
    ON [dbo].[ManufacturingActivityLogs]([OrderManufacturingWorkflowId] ASC) WITH (FILLFACTOR = 80);


GO

