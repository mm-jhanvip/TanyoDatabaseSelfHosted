CREATE TABLE [dbo].[CustomerContacts] (
    [Id]                  BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]          BIGINT             NOT NULL,
    [Name]                VARCHAR (100)      NULL,
    [Email]               VARCHAR (100)      NULL,
    [MobileNo]            VARCHAR (15)       NULL,
    [LastModifiedBy]      BIGINT             NOT NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

