CREATE TABLE [dbo].[FollowUpOrders] (
    [FollowUpOrdersId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]          BIGINT             NOT NULL,
    [FollowUpDate]     DATETIME           NULL,
    [FollowUpComment]  NVARCHAR (MAX)     NULL,
    [CreatedBy]        INT                NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    PRIMARY KEY CLUSTERED ([FollowUpOrdersId] ASC)
);


GO

