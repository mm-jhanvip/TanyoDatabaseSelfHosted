CREATE TABLE [dbo].[ManufacturingWorkflowMapping] (
    [ManufacturingWorkflowMappingId] INT                IDENTITY (1, 1) NOT NULL,
    [ManufacturingUserId]            INT                NOT NULL,
    [ManufacturingWorkflowId]        INT                NOT NULL,
    [IsDeleted]                      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]                      INT                NOT NULL,
    [CreatedDate]                    DATETIMEOFFSET (7) CONSTRAINT [DF__Contracto__Creat__0C50D423] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                 DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                      INT                NULL,
    [UpdatedDate]                    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]                 DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([ManufacturingWorkflowMappingId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ManufacturingWorkflowMapping_ManufacturingUserId_IsDeleted]
    ON [dbo].[ManufacturingWorkflowMapping]([ManufacturingUserId] ASC, [IsDeleted] ASC)
    INCLUDE([CreatedBy]) WITH (FILLFACTOR = 70);


GO

