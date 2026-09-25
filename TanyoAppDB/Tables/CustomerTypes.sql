CREATE TABLE [dbo].[CustomerTypes] (
    [CustomerTypeId] INT                IDENTITY (1, 1) NOT NULL,
    [Name]           VARCHAR (50)       NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__CustomerT__Creat__5D2BD0E6] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([CustomerTypeId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_CustomerTypes_IsDeleted_CreatedBy]
    ON [dbo].[CustomerTypes]([IsDeleted] ASC, [CreatedBy] ASC);


GO

