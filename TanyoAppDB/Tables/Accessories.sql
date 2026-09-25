CREATE TABLE [dbo].[Accessories] (
    [AccessoriesId]     INT                                                 IDENTITY (1, 1) NOT NULL,
    [CategoryId]        INT                                                 NOT NULL,
    [AccessoriesTypeId] INT                                                 NOT NULL,
    [Title]             VARCHAR (150)                                       NOT NULL,
    [UnitId]            INT                                                 NOT NULL,
    [UnitPrice]         NUMERIC (8, 2) NOT NULL,
    [ImagePath]         VARCHAR (500)                                       NULL,
    [TenantId]          INT                                                 NOT NULL,
    [IsDeleted]         BIT                                                 DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                                                 NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7)                                  CONSTRAINT [DF__Accessori__Creat__7720AD13] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME                                            DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                                                 NULL,
    [UpdatedDate]       DATETIMEOFFSET (7)                                  NULL,
    [UpdatedUTCDate]    DATETIME                                            NULL,
    PRIMARY KEY CLUSTERED ([AccessoriesId] ASC)
);


GO

