CREATE TABLE [dbo].[Archive_Orders] (
    [Archive_OrderId]              BIGINT             IDENTITY (233459, 1) NOT NULL,
    [VersionId]                    BIGINT             NOT NULL,
    [OrderId]                      BIGINT             NOT NULL,
    [OrderNo]                      VARCHAR (20)       NOT NULL,
    [CustomerID]                   BIGINT             NOT NULL,
    [RefferedBy]                   BIGINT             NULL,
    [GrossTotal]                   NUMERIC (18, 2)    NOT NULL,
    [Discount]                     NUMERIC (18, 2)    NOT NULL,
    [TotalAmount]                  NUMERIC (18)       NOT NULL,
    [AmountBeforeGST]              NUMERIC (18, 2)    CONSTRAINT [DF_Archive_AmountBeforeGST] DEFAULT ((0)) NOT NULL,
    [CGSTAmount]                   NUMERIC (18, 2)    CONSTRAINT [DF_Archive_CGSTAmount] DEFAULT ((0)) NOT NULL,
    [SGSTAmount]                   NUMERIC (18, 2)    CONSTRAINT [DF_Archive_SGSTAmount] DEFAULT ((0)) NOT NULL,
    [GSTTaxAmount]                 NUMERIC (18, 2)    NOT NULL,
    [AdvanceAmount]                NUMERIC (9, 2)     NOT NULL,
    [DeliveryDate]                 DATE               NULL,
    [Comments]                     NVARCHAR (MAX)     NULL,
    [Status]                       INT                CONSTRAINT [DF_Archive_Status] DEFAULT ((1)) NOT NULL,
    [TenantId]                     INT                NOT NULL,
    [InquiryExpirationDate]        DATETIMEOFFSET (7) NULL,
    [DeliveryCharges]              NUMERIC (18, 2)    NULL,
    [ApprovedDate]                 DATETIMEOFFSET (7) NULL,
    [TentativeDeliveryDate]        DATE               NULL,
    [OrderType]                    SMALLINT           CONSTRAINT [DF_Archive_OrderType] DEFAULT ((1)) NULL,
    [OfferDiscount]                NUMERIC (18, 2)    CONSTRAINT [DF_Archive_OfferDiscount] DEFAULT ((0)) NOT NULL,
    [IsFreeDelivery]               BIT                CONSTRAINT [DF_Archive_IsFreeDelivery] DEFAULT ((0)) NOT NULL,
    [CreatedBy]                    INT                NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) CONSTRAINT [DF_Archive_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]               DATETIME           CONSTRAINT [DF_Archive_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    INT                NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    [TotalAmt]                     AS                 (([AmountBeforeGST]+[CGSTAmount])+[SGSTAmount]),
    [InquiryLastUpdatedDate]       DATETIMEOFFSET (7) NULL,
    [LabelId]                      BIGINT             NULL,
    [GSTType]                      BIT                CONSTRAINT [DF_Archive_GSTType] DEFAULT ((0)) NOT NULL,
    [LumpsumDiscount]              NUMERIC (18, 2)    NULL,
    [DeliveryAmount]               NUMERIC (9)        NULL,
    [DeliveryAmountCollectionType] INT                NULL,
    [DeliveryCharge]               TINYINT            NULL,
    [SalesmanId]                   INT                NOT NULL,
    [InteriorCommissionPer]        NUMERIC (5, 2)     DEFAULT ((0)) NULL,
    [ArchiveOrderDate]             DATETIMEOFFSET (7) CONSTRAINT [DF_Archive_ArchiveOrderDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [ArchiveOrderUTCDate]          DATETIME           CONSTRAINT [DF_Archive_ArchiveOrderUTCDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_Archive_Orders] PRIMARY KEY CLUSTERED ([Archive_OrderId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_Cover]
    ON [dbo].[Archive_Orders]([OrderId] ASC);


GO

