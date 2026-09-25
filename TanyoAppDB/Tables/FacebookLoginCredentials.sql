CREATE TABLE [dbo].[FacebookLoginCredentials] (
    [FacebookLoginCredentialID]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [TenantId]                          VARCHAR (900) NOT NULL,
    [Email]                             VARCHAR (50)  NULL,
    [AccessToken]                       VARCHAR (400) NOT NULL,
    [ExpiredDate]                       DATETIME      NULL,
    [FacebookUserID]                    VARCHAR (200) NULL,
    [FacebbokUserName]                  VARCHAR (200) NULL,
    [LongTermUserAccessToken]           VARCHAR (400) NULL,
    [LongTermUserAccessTokenExpiryDate] DATETIME      NULL,
    [CreatedBy]                         VARCHAR (900) NOT NULL,
    [CreatedDate]                       DATETIME      NOT NULL,
    [CreatedUTCDate]                    DATETIME      NOT NULL,
    [UpdatedBy]                         VARCHAR (900) NULL,
    [UpdatedDate]                       DATETIME      NULL,
    [UpdatedUTCDate]                    DATETIME      NULL,
    [TokenUpdatedDate]                  DATETIME      NOT NULL,
    CONSTRAINT [PK_FacebookLoginCredentials] PRIMARY KEY CLUSTERED ([FacebookLoginCredentialID] ASC)
);


GO

