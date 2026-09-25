CREATE TABLE [dbo].[ProductSets] (
    [ProductSetId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [SetName]        VARCHAR (255)      NOT NULL,
    [Description]    VARCHAR (MAX)      NULL,
    [QRImage]        VARCHAR (MAX)      NOT NULL,
    [SetImage]       VARCHAR (MAX)      NULL,
    [TenantId]       INT                NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF_ProductSets_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_ProductSets_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_ProductSets_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([ProductSetId] ASC)
);


GO

