CREATE TABLE [dbo].[Archive_OrderSets] (
    [Archive_OrderSetId]     INT                IDENTITY (251779, 1) NOT NULL,
    [VersionId]              BIGINT             NOT NULL,
    [Archive_OrderVersionId] BIGINT             NOT NULL,
    [OrderSetId]             BIGINT             NOT NULL,
    [OrderId]                BIGINT             NOT NULL,
    [SetName]                VARCHAR (100)      NOT NULL,
    [CreatedBy]              INT                NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) CONSTRAINT [DF_Archive_OrderSets_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]         DATETIME           CONSTRAINT [DF_Archive_OrderSets_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              INT                NULL,
    [UpdatedDate]            DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    [IsDeleted]              BIT                CONSTRAINT [DF_Archive_OrderSets_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Archive_OrderSets] PRIMARY KEY CLUSTERED ([Archive_OrderSetId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_Archive_OrderSets_cover]
    ON [dbo].[Archive_OrderSets]([VersionId] ASC, [Archive_OrderVersionId] ASC, [OrderSetId] ASC, [OrderId] ASC);


GO

