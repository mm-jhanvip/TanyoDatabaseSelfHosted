CREATE TABLE [dbo].[ManufacturingWorkflows] (
    [ManufacturingWorkflowId] INT                IDENTITY (1, 1) NOT NULL,
    [WorkflowName]            VARCHAR (50)       NOT NULL,
    [TenantId]                BIGINT             NOT NULL,
    [IsDeleted]               BIT                CONSTRAINT [DF__Workflows__IsDel__7B113988] DEFAULT ((0)) NOT NULL,
    [CreatedBy]               INT                NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) CONSTRAINT [DF__Workflows__Creat__7C055DC1] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           CONSTRAINT [DF__Workflows__Creat__7CF981FA] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               INT                NULL,
    [UpdatedDate]             DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]          DATETIME           NULL,
    [SendSMS]                 BIT                DEFAULT ((0)) NOT NULL,
    [SendWhatsApp]            BIT                DEFAULT ((0)) NOT NULL,
    [SendPushNotification]    BIT                DEFAULT ((0)) NOT NULL,
    [IsSupervisionRequired]   BIT                DEFAULT ((0)) NOT NULL,
    [IsAttachmentRequired]    BIT                DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__Workflow__5704A64A3FDA485B] PRIMARY KEY CLUSTERED ([ManufacturingWorkflowId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ManufacturingWorkflows_TenantId_WorkflowId]
    ON [dbo].[ManufacturingWorkflows]([TenantId] ASC);


GO

