CREATE TABLE [dbo].[Archive_Orders20260128] (
    [Archive_OrderId]              BIGINT             IDENTITY (1, 1) NOT NULL,
    [VersionId]                    BIGINT             NOT NULL,
    [OrderId]                      BIGINT             NOT NULL,
    [OrderNo]                      VARCHAR (20)       NOT NULL,
    [CustomerID]                   BIGINT             NOT NULL,
    [RefferedBy]                   BIGINT             NULL,
    [GrossTotal]                   NUMERIC (18, 2)    NOT NULL,
    [Discount]                     NUMERIC (18, 2)    NOT NULL,
    [TotalAmount]                  NUMERIC (18)       NOT NULL,
    [AmountBeforeGST]              NUMERIC (18, 2)    CONSTRAINT [df_Archive_AmountBeforeGST] DEFAULT ((0)) NOT NULL,
    [CGSTAmount]                   NUMERIC (18, 2)    CONSTRAINT [df_Archive_CGSTAmount] DEFAULT ((0)) NOT NULL,
    [SGSTAmount]                   NUMERIC (18, 2)    CONSTRAINT [df_Archive_SGSTAmount] DEFAULT ((0)) NOT NULL,
    [GSTTaxAmount]                 NUMERIC (18, 2)    NOT NULL,
    [AdvanceAmount]                NUMERIC (9, 2)     NOT NULL,
    [DeliveryDate]                 DATE               NULL,
    [Comments]                     NVARCHAR (MAX)     NULL,
    [Status]                       INT                CONSTRAINT [DF__Archive_Orders__Status__30242045] DEFAULT ((1)) NOT NULL,
    [TenantId]                     INT                NOT NULL,
    [InquiryExpirationDate]        DATETIMEOFFSET (7) NULL,
    [DeliveryCharges]              NUMERIC (18, 2)    NULL,
    [ApprovedDate]                 DATETIMEOFFSET (7) NULL,
    [TentativeDeliveryDate]        DATE               NULL,
    [OrderType]                    SMALLINT           CONSTRAINT [DF__Archive_Orders__OrderTyp__5540965B] DEFAULT ((1)) NULL,
    [OfferDiscount]                NUMERIC (18, 2)    CONSTRAINT [df_Archive_OfferAmount] DEFAULT ((0)) NOT NULL,
    [IsFreeDelivery]               BIT                CONSTRAINT [DF__Archive_Orders__IsFreeDe__797DF6D1] DEFAULT ((0)) NOT NULL,
    [CreatedBy]                    INT                NOT NULL,
    [CreatedDate]                  DATETIMEOFFSET (7) CONSTRAINT [DF__Archive_Orders__CreatedD__320C68B7] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]               DATETIME           CONSTRAINT [DF__Archive_Orders__CreatedU__33008CF0] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    INT                NULL,
    [UpdatedDate]                  DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]               DATETIME           NULL,
    [TotalAmt]                     AS                 (([AmountBeforeGST]+[CGSTAmount])+[SGSTAmount]),
    [InquiryLastUpdatedDate]       DATETIMEOFFSET (7) NULL,
    [LabelId]                      BIGINT             NULL,
    [GSTType]                      BIT                CONSTRAINT [DF__Archive_Orders__GSTType__0AFD888E] DEFAULT ((0)) NOT NULL,
    [LumpsumDiscount]              NUMERIC (18, 2)    NULL,
    [DeliveryAmount]               NUMERIC (9)        NULL,
    [DeliveryAmountCollectionType] INT                NULL,
    [DeliveryCharge]               TINYINT            NULL,
    [SalesmanId]                   INT                NOT NULL,
    [InteriorCommissionPer]        NUMERIC (5, 2)     DEFAULT ((0)) NULL,
    [ArchiveOrderDate]             DATETIMEOFFSET (7) CONSTRAINT [DF_ArchiveOrderDateArchiveOrders] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [ArchiveOrderUTCDate]          DATETIME           CONSTRAINT [DF_ArchiveOrderUTCDateArchiveOrders] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK__Archive_Orders] PRIMARY KEY CLUSTERED ([Archive_OrderId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_Archive_Orders_cover]
    ON [dbo].[Archive_Orders20260128]([OrderId] ASC)
    INCLUDE([VersionId]) WITH (FILLFACTOR = 70);


GO

