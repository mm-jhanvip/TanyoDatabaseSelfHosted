CREATE TABLE [dbo].[OwnerActionItems] (
    [ActionId]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]          INT                NOT NULL,
    [Problem]           VARCHAR (500)      NOT NULL,
    [ActionRequired]    VARCHAR (500)      NOT NULL,
    [ResponsiblePerson] VARCHAR (200)      NOT NULL,
    [Deadline]          DATE               NOT NULL,
    [Status]            INT                CONSTRAINT [DF_OwnerActionItems_Status] DEFAULT ((0)) NOT NULL,
    [ActionDate]        DATE               CONSTRAINT [DF_OwnerActionItems_ActionDate] DEFAULT (CONVERT([date],getdate())) NOT NULL,
    [IsDeleted]         BIT                CONSTRAINT [DF_OwnerActionItems_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) CONSTRAINT [DF_OwnerActionItems_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           CONSTRAINT [DF_OwnerActionItems_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    CONSTRAINT [PK_OwnerActionItems] PRIMARY KEY CLUSTERED ([ActionId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_OwnerActionItems_Tenant_ActionDate]
    ON [dbo].[OwnerActionItems]([TenantId] ASC, [ActionDate] ASC)
    INCLUDE([Status]);


GO

