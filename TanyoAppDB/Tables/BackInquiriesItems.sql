CREATE TABLE [dbo].[BackInquiriesItems] (
    [ID]                           BIGINT             IDENTITY (1, 1) NOT NULL,
    [BackInquiryID]                BIGINT             NULL,
    [ProductID]                    BIGINT             NULL,
    [VendorProductID]              BIGINT             NULL,
    [Qty]                          DECIMAL (18, 2)    NULL,
    [TentativeDeliveryDate]        DATE               NULL,
    [Status]                       INT                NOT NULL,
    [CreatedBy]                    BIGINT             NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) CONSTRAINT [DF__BackInqui__Creat__22A007F5] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]               DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    BIGINT             NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    [UpdatedQty]                   DECIMAL (18)       NULL,
    [UpdatedTentativeDeliveryDate] DATE               NULL,
    [SenderComment]                NVARCHAR (MAX)     NULL,
    [ReceiverComment]              NVARCHAR (MAX)     NULL,
    [RequestedPrice]               DECIMAL (18, 2)    NULL,
    [ApprovedPrice]                DECIMAL (18, 2)    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

