CREATE TABLE [dbo].[UserTenantMapping] (
    [UserTenantMappingId] INT                IDENTITY (1, 1) NOT NULL,
    [UserId]              INT                NOT NULL,
    [TenantId]            INT                NOT NULL,
    [IsDeleted]           BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]           INT                NOT NULL,
    [CreatedDate]         DATETIMEOFFSET (7) CONSTRAINT [DF__UserTenan__Creat__02C769E9] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]      DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           INT                NULL,
    [UpdatedDate]         DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]      DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([UserTenantMappingId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_UserTenantMapping_UserId]
    ON [dbo].[UserTenantMapping]([UserId] ASC) WITH (FILLFACTOR = 70);


GO

