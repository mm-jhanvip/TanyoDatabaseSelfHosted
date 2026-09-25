CREATE TABLE [dbo].[NotificationManagement_20231027_1646] (
    [NotificationManagementID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [EntityTypeID]             BIGINT             NOT NULL,
    [EntityID]                 BIGINT             NOT NULL,
    [NotificationType]         VARCHAR (50)       NOT NULL,
    [NotificationMethod]       VARCHAR (50)       NOT NULL,
    [MessageSubject]           NVARCHAR (500)     NULL,
    [MessageBody]              NVARCHAR (MAX)     NULL,
    [ReceiverEmail]            VARCHAR (100)      NULL,
    [ReceiverMobile]           VARCHAR (20)       NULL,
    [Status]                   INT                NOT NULL,
    [CreatedBy]                BIGINT             NOT NULL,
    [CreatedDate]              DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]           DATETIME           NOT NULL,
    [UpdatedBy]                BIGINT             NULL,
    [UpdatedDate]              DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]           DATETIME           NULL,
    [TenantId]                 INT                NOT NULL,
    [Response]                 VARCHAR (MAX)      NULL
);


GO

