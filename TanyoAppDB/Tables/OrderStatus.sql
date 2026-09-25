CREATE TABLE [dbo].[OrderStatus] (
    [OrderStatusId] BIGINT       IDENTITY (1, 1) NOT NULL,
    [StatusEnumId]  INT          NULL,
    [TenantId]      INT          NULL,
    [Status]        VARCHAR (25) NULL,
    [StatusLabel]   VARCHAR (25) NULL,
    [Type]          VARCHAR (20) NULL,
    CONSTRAINT [PK_StatusLabel] PRIMARY KEY CLUSTERED ([OrderStatusId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_OrderStatus_Cover]
    ON [dbo].[OrderStatus]([TenantId] ASC, [Status] ASC)
    INCLUDE([OrderStatusId], [StatusEnumId]);


GO

