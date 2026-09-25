CREATE TABLE [dbo].[FacebookAPIPageDetails] (
    [FacebookAPIPageDetailsID]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [PageAccessToken]           VARCHAR (400) NULL,
    [Category]                  VARCHAR (400) NULL,
    [CategoriesList]            VARCHAR (MAX) NULL,
    [PageName]                  VARCHAR (400) NULL,
    [PageID]                    VARCHAR (400) NULL,
    [Tasks]                     VARCHAR (MAX) NULL,
    [LongTermPageAccessToken]   VARCHAR (400) NULL,
    [PageTokenCreatedDate]      DATETIME      NOT NULL,
    [FacebookLoginCredentialID] BIGINT        NOT NULL,
    [TenantId]                  VARCHAR (900) NOT NULL,
    [CreatedBy]                 VARCHAR (100) NOT NULL,
    [CreatedDate]               DATETIME      CONSTRAINT [DF_FacebookAPIPageDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate]            DATETIME      CONSTRAINT [DF_FacebookAPIPageDetails_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 BIGINT        NULL,
    [UpdatedDate]               DATETIME      NULL,
    [UpdatedUTCDate]            DATETIME      NULL,
    [IGUserID]                  VARCHAR (400) NULL,
    [IsActive]                  BIT           NULL,
    CONSTRAINT [PK_FacebookAPIPageDetails] PRIMARY KEY CLUSTERED ([FacebookAPIPageDetailsID] ASC)
);


GO

