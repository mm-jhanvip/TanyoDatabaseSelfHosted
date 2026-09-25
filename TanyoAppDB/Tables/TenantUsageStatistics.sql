CREATE TABLE [dbo].[TenantUsageStatistics] (
    [Id]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]       BIGINT             NOT NULL,
    [Month]          VARCHAR (50)       NOT NULL,
    [Year]           INT                NOT NULL,
    [ModuleName]     VARCHAR (50)       NOT NULL,
    [TotalCount]     INT                NOT NULL,
    [Position]       INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO

