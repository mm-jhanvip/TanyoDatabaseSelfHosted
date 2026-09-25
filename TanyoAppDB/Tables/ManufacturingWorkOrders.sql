CREATE TABLE [dbo].[ManufacturingWorkOrders] (
    [ManufacturingWorkOrderId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderSetItemId]           BIGINT             NOT NULL,
    [OrderId]                  BIGINT             NOT NULL,
    [Status]                   INT                DEFAULT ((0)) NOT NULL,
    [IsDeleted]                BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]                INT                NOT NULL,
    [CreatedDate]              DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]           DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                BIGINT             NULL,
    [UpdatedDate]              DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]           DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([ManufacturingWorkOrderId] ASC)
);


GO

