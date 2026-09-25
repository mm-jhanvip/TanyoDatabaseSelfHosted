CREATE TABLE [dbo].[AccessoriesTypes] (
    [AccessoriesTypeId] INT                IDENTITY (1, 1) NOT NULL,
    [CategoryId]        INT                NOT NULL,
    [TypeName]          VARCHAR (100)      NOT NULL,
    [TenantId]          INT                NOT NULL,
    [IsDeleted]         BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) CONSTRAINT [DF__Accessori__Creat__725BF7F6] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([AccessoriesTypeId] ASC)
);


GO

