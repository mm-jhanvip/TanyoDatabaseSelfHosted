CREATE TABLE [dbo].[CatalogueAnonymousViews] (
    [CatalogueAnonymousViewId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CatalogueId]              BIGINT             NOT NULL,
    [IPAddress]                VARCHAR (50)       NOT NULL,
    [CreatedDate]              DATETIMEOFFSET (7) CONSTRAINT [DF__CatalogueAnon__Creat__6DEC4894] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]           DATETIME           DEFAULT (getutcdate()) NULL,
    [BrowserName]              VARCHAR (1000)     DEFAULT (NULL) NULL,
    PRIMARY KEY CLUSTERED ([CatalogueAnonymousViewId] ASC)
);


GO

