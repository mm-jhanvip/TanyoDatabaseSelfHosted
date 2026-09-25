CREATE TABLE [dbo].[CategoriesAnonymousViews] (
    [CategoriesAnonymousViewId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CategoriesId]              BIGINT             NOT NULL,
    [IPAddress]                 VARCHAR (50)       NOT NULL,
    [CreatedDate]               DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]            DATETIME           NULL,
    [BrowserName]               VARCHAR (1000)     NULL,
    PRIMARY KEY CLUSTERED ([CategoriesAnonymousViewId] ASC)
);


GO

