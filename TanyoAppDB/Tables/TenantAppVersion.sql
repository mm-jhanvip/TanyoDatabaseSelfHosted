CREATE TABLE [dbo].[TenantAppVersion] (
    [TenantAppVersionId]  INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]            INT                NOT NULL,
    [DeviceType]          VARCHAR (20)       NOT NULL,
    [AppVersion]          VARCHAR (20)       NOT NULL,
    [IsForceUpdate]       BIT                DEFAULT ((0)) NOT NULL,
    [IsMaintenance]       BIT                DEFAULT ((0)) NOT NULL,
    [LastModifiedBy]      BIGINT             NOT NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([TenantAppVersionId] ASC)
);


GO

