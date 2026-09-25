CREATE TABLE [dbo].[OrderManufacturingWorkflows] (
    [OrderManufacturingWorkflowId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]                      BIGINT             NOT NULL,
    [OrderSetItemId]               BIGINT             NOT NULL,
    [ManufacturingWorkflowId]      BIGINT             NOT NULL,
    [ContractorUserID]             BIGINT             NOT NULL,
    [SupervisorUserID]             BIGINT             NOT NULL,
    [Position]                     INT                CONSTRAINT [DF_OrderManufacturingWorkflows_Position] DEFAULT ((0)) NULL,
    [ManufacturingStatus]          INT                CONSTRAINT [DF__OrderManu__Manuf__705EA0EB] DEFAULT ((0)) NOT NULL,
    [ManufacturingDeliveryDate]    DATETIMEOFFSET (7) NULL,
    [CreatedBy]                    BIGINT             NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) CONSTRAINT [DF__OrderManu__Creat__7152C524] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]               DATETIME           CONSTRAINT [DF__OrderManu__Creat__7246E95D] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    BIGINT             NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    [CompletionDate]               DATE               NULL,
    [AcceptedDate]                 DATETIME           NULL,
    [LabourCharge]                 NUMERIC (18, 2)    CONSTRAINT [DF_OrderManufacturingWorkflows_LabourCharge] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__OrderMan__75C705A89A6C0CC6] PRIMARY KEY CLUSTERED ([OrderManufacturingWorkflowId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderManufacturingWorkflows_Status_WorkflowId_ContractorUserId]
    ON [dbo].[OrderManufacturingWorkflows]([OrderId] ASC, [CompletionDate] ASC, [ManufacturingWorkflowId] ASC, [ManufacturingStatus] ASC, [ContractorUserID] ASC) WITH (FILLFACTOR = 80);


GO

EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'0 Pending, 1 In Progress, 2 Submitted, 3 Approved, 4 Completed', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'OrderManufacturingWorkflows', @level2type = N'COLUMN', @level2name = N'ManufacturingStatus';


GO

