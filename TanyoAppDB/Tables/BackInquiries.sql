CREATE TABLE [dbo].[BackInquiries] (
    [ID]              BIGINT             IDENTITY (1, 1) NOT NULL,
    [VendorID]        BIGINT             NOT NULL,
    [TenantID]        INT                NOT NULL,
    [CreatedBy]       BIGINT             NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__BackInqui__Creat__1ECF7711] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       BIGINT             NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [SenderComment]   NVARCHAR (MAX)     NULL,
    [ReceiverComment] NVARCHAR (MAX)     NULL,
    [PONumber]        VARCHAR (20)       NULL,
    [OrderId]         BIGINT             NULL,
    [SalesmanId]      BIGINT             NULL,
    [CustomerId]      BIGINT             NULL,
    [ToTenantID]      INT                NULL,
    [Status]          INT                NULL,
    [ReasonId]        BIGINT             NULL,
    [ReasonText]      NVARCHAR (MAX)     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_BackInquiries_cover]
    ON [dbo].[BackInquiries]([VendorID] ASC, [TenantID] ASC, [OrderId] ASC, [SalesmanId] ASC, [CustomerId] ASC);


GO

