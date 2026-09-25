CREATE TABLE [dbo].[Frames] (
    [FrameId]        INT                IDENTITY (1, 1) NOT NULL,
    [FrameTypeId]    INT                NOT NULL,
    [Title]          VARCHAR (150)      NOT NULL,
    [ModelNo]        VARCHAR (50)       NOT NULL,
    [CompanyId]      INT                NULL,
    [UnitId]         INT                NOT NULL,
    [UnitPrice]      NUMERIC (8, 2)     NOT NULL,
    [ImagePath]      VARCHAR (500)      NULL,
    [TenantId]       INT                NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Woods__CreatedDa__0A338187] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([FrameId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_Frames_FrameTypeId]
    ON [dbo].[Frames]([FrameTypeId] ASC, [CompanyId] ASC, [TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([Title], [ModelNo], [UnitId], [UnitPrice], [ImagePath]);


GO

