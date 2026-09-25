CREATE TABLE [dbo].[CustomerImages] (
    [CustomerImageId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]      BIGINT             NOT NULL,
    [ImageName]       VARCHAR (200)      NOT NULL,
    [ImagePath]       VARCHAR (MAX)      NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerImageId] ASC)
);


GO

