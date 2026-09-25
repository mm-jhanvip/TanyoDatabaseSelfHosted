CREATE TABLE [dbo].[DeviceLogs] (
    [DeviceLogId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserID]      BIGINT        NOT NULL,
    [TenantID]    INT           NOT NULL,
    [AppVersion]  VARCHAR (50)  NULL,
    [Device]      VARCHAR (500) NULL,
    [OSVersion]   VARCHAR (500) NULL,
    [Module]      VARCHAR (100) NULL,
    [Message]     VARCHAR (MAX) NULL,
    [RecordDate]  DATETIME      DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([DeviceLogId] ASC)
);


GO

