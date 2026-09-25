CREATE TABLE [dbo].[OrderDeliveryDateMissing] (
    [OrderId]                BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderNo]                VARCHAR (20)       NOT NULL,
    [CustomerID]             BIGINT             NOT NULL,
    [RefferedBy]             BIGINT             NULL,
    [GrossTotal]             NUMERIC (18, 2)    NOT NULL,
    [Discount]               NUMERIC (18, 2)    NOT NULL,
    [TotalAmount]            NUMERIC (18, 2)    NOT NULL,
    [TotalAmt]               NUMERIC (20, 2)    NULL,
    [AmountBeforeGST]        NUMERIC (18, 2)    NULL,
    [CGSTAmount]             NUMERIC (18, 2)    NULL,
    [SGSTAmount]             NUMERIC (18, 2)    NULL,
    [GSTTaxAmount]           NUMERIC (18, 2)    NOT NULL,
    [AdvanceAmount]          NUMERIC (9, 2)     NOT NULL,
    [DeliveryDate]           DATE               NULL,
    [Comments]               NVARCHAR (MAX)     NULL,
    [IsFreeDelivery]         BIT                NOT NULL,
    [Status]                 INT                NOT NULL,
    [TenantId]               INT                NOT NULL,
    [InquiryExpirationDate]  DATETIMEOFFSET (7) NULL,
    [DeliveryCharges]        NUMERIC (18, 2)    NULL,
    [ApprovedDate]           DATETIMEOFFSET (7) NULL,
    [TentativeDeliveryDate]  DATE               NULL,
    [OrderType]              SMALLINT           NOT NULL,
    [OfferDiscount]          NUMERIC (18, 2)    NULL,
    [CreatedBy]              INT                NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]         DATETIME           NOT NULL,
    [UpdatedBy]              INT                NULL,
    [UpdatedDate]            DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    [InquiryLastUpdatedDate] DATETIMEOFFSET (7) NULL
);


GO

