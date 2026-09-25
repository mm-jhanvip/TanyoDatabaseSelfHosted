CREATE TABLE [dbo].[OrderRequestLog] (
    [OrderRequestLogId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [TenantId]          BIGINT             NOT NULL,
    [OrderId]           BIGINT             NOT NULL,
    [OrderNo]           VARCHAR (20)       NOT NULL,
    [UserId]            BIGINT             NOT NULL,
    [RequestJSONObject] NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]         BIGINT             NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderRequestLogId] ASC)
);


GO

