CREATE TABLE [dbo].[TallyConfiguration] (
    [TallyId]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [TallyURLPort]        VARCHAR (50)  NULL,
    [TallyPassword]       VARCHAR (50)  NULL,
    [TallyUsername]       VARCHAR (50)  NULL,
    [IsTallyEnabled]      BIT           NULL,
    [SalesLedgerName]     VARCHAR (100) NULL,
    [CompanyName]         VARCHAR (100) NULL,
    [TenantId]            BIGINT        NOT NULL,
    [TallyServiceURLPort] VARCHAR (50)  NULL,
    [PurchaseLedgerName]  VARCHAR (255) NULL,
    CONSTRAINT [PK_TallyConfiguration] PRIMARY KEY CLUSTERED ([TallyId] ASC)
);


GO

