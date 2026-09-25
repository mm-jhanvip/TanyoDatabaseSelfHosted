CREATE TABLE [dbo].[SalesTargets] (
    [SalesTargetId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NOT NULL,
    [UserId]         INT                NOT NULL,
    [Month]          INT                NOT NULL,
    [Year]           INT                NOT NULL,
    [TargetAmount]   DECIMAL (18, 2)    CONSTRAINT [DF_SalesTargets_TargetAmount] DEFAULT ((0)) NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF_SalesTargets_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_SalesTargets_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_SalesTargets_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK_SalesTargets] PRIMARY KEY CLUSTERED ([SalesTargetId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_SalesTargets_Tenant_Month_Year]
    ON [dbo].[SalesTargets]([TenantId] ASC, [Year] ASC, [Month] ASC)
    INCLUDE([UserId], [TargetAmount]);


GO

