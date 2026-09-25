CREATE TABLE [dbo].[CustomerFamily] (
    [CustFamilyId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [FamilyName]     VARCHAR (256)      NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_CustomerFamily_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedDateUTC] DATETIME           CONSTRAINT [DF_CustomerFamily_CreatedDateUTC] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([CustFamilyId] ASC)
);


GO

