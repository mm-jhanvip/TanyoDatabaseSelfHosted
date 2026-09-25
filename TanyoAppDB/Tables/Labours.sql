CREATE TABLE [dbo].[Labours] (
    [LabourId]       INT                IDENTITY (1, 1) NOT NULL,
    [Title]          VARCHAR (150)      NOT NULL,
    [UnitId]         INT                NOT NULL,
    [UnitPrice]      NUMERIC (8, 2)     NOT NULL,
    [TenantId]       INT                NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Labours__Created__764C846B] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([LabourId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Labours_TenantId_IsDeleted]
    ON [dbo].[Labours]([TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([Title], [UnitId], [UnitPrice]);


GO

