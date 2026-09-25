CREATE TABLE [dbo].[NotificationTemplate] (
    [Id]                  BIGINT          IDENTITY (1, 1) NOT NULL,
    [MinAmount]           DECIMAL (18, 2) NOT NULL,
    [MaxAmount]           DECIMAL (18, 2) NOT NULL,
    [NotificationMessage] NVARCHAR (250)  NULL,
    [TenantId]            INT             NOT NULL,
    [IsDeleted]           BIT             DEFAULT ((0)) NOT NULL,
    [CreatedBy]           INT             NOT NULL,
    [CreatedDate]         DATETIME        DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate]      DATETIME        DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           INT             NULL,
    [UpdatedDate]         DATETIME        NULL,
    [UpdatedUTCDate]      DATETIME        NULL
);


GO

