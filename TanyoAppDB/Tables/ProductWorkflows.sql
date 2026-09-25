CREATE TABLE [dbo].[ProductWorkflows] (
    [ProductWorkflowID]       BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductID]               BIGINT             NOT NULL,
    [ManufacturingWorkflowId] BIGINT             NOT NULL,
    [ContractorUserID]        BIGINT             NOT NULL,
    [SupervisorUserID]        BIGINT             NOT NULL,
    [TentativeDays]           NUMERIC (5, 2)     NOT NULL,
    [Position]                INT                NOT NULL,
    [CreatedBy]               INT                NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) CONSTRAINT [DF_ProductWorkflows_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           CONSTRAINT [df_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               INT                NULL,
    [UpdatedDate]             DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]          DATETIME           NULL,
    [LabourCharge]            NUMERIC (18, 2)    CONSTRAINT [DF_ProductWorkflows_LabourCharge] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ProductWorkflows] PRIMARY KEY CLUSTERED ([ProductWorkflowID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ProductWorkflows_ProductID_ManufacturingWorkflowId]
    ON [dbo].[ProductWorkflows]([ProductID] ASC, [ManufacturingWorkflowId] ASC) WITH (FILLFACTOR = 70);


GO

