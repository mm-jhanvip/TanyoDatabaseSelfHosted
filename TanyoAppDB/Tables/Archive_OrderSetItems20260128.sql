CREATE TABLE [dbo].[Archive_OrderSetItems20260128] (
    [Archive_OrderSetItemId]     BIGINT             IDENTITY (1, 1) NOT NULL,
    [VersionId]                  BIGINT             NOT NULL,
    [Archive_OrderVersionId]     BIGINT             NOT NULL,
    [Archive_OrderSetsVersionId] BIGINT             NOT NULL,
    [OrderSetItemId]             BIGINT             NOT NULL,
    [ParentOrderSetItemId]       BIGINT             NULL,
    [OrderId]                    BIGINT             NOT NULL,
    [OrderSetId]                 BIGINT             NOT NULL,
    [DeliveryNo]                 VARCHAR (50)       NULL,
    [SubjectTypeId]              INT                NOT NULL,
    [SubjectId]                  BIGINT             NOT NULL,
    [DeliveryDate]               DATE               NULL,
    [UnitPrice]                  NUMERIC (18, 2)    NOT NULL,
    [DiscountPrice]              NUMERIC (18, 2)    CONSTRAINT [DF_Archive_OrderSetItems_Discount] DEFAULT ((0)) NOT NULL,
    [GrossTotal]                 NUMERIC (18, 2)    CONSTRAINT [DF__Archive_OrderSetI__Gross__094A4A46] DEFAULT ((0)) NOT NULL,
    [Discount]                   NUMERIC (18, 2)    CONSTRAINT [DF__Archive_OrderSetI__Disco__0A3E6E7F] DEFAULT ((0)) NOT NULL,
    [TotalAmount]                NUMERIC (18, 2)    NOT NULL,
    [AmountBeforeGST]            NUMERIC (18, 2)    NOT NULL,
    [CGSTAmount]                 NUMERIC (18, 2)    NOT NULL,
    [SGSTAmount]                 NUMERIC (18, 2)    NOT NULL,
    [ProductImage]               VARCHAR (MAX)      NULL,
    [Width]                      NUMERIC (18, 2)    NULL,
    [Height]                     NUMERIC (18, 2)    NULL,
    [Depth]                      NUMERIC (18, 2)    NULL,
    [Diameter]                   NUMERIC (18, 2)    NULL,
    [Quantity]                   NUMERIC (18, 2)    NOT NULL,
    [Comment]                    NVARCHAR (MAX)     NULL,
    [ItemStatus]                 INT                NOT NULL,
    [ReceiveDate]                DATETIMEOFFSET (7) NULL,
    [ProvidedMaterial]           NUMERIC (5, 2)     NULL,
    [CreatedBy]                  INT                NOT NULL,
    [CreatedDate]                DATETIMEOFFSET (7) CONSTRAINT [DF__Archive_OrderSetI__Creat__7D98A078] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]             DATETIME           CONSTRAINT [DF__Archive_OrderSetI__Creat__7E8CC4B1] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                  INT                NULL,
    [UpdatedDate]                DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]             DATETIME           NULL,
    [DeliveryComment]            NVARCHAR (MAX)     NULL,
    [GST]                        NUMERIC (18, 2)    CONSTRAINT [DF__Archive_OrderSetIte__GST__3BA0BFE9] DEFAULT ((18)) NOT NULL,
    [CostPrice]                  NUMERIC (18, 2)    CONSTRAINT [DF__Archive_OrderSetI__CostP__3C94E422] DEFAULT ((0)) NOT NULL,
    [IsDeleted]                  BIT                CONSTRAINT [DF__Archive_OrderSetI__IsDel__7D6E8346] DEFAULT ((0)) NOT NULL,
    [OfferId]                    INT                NULL,
    [InstantUnitPrice]           NUMERIC (18, 2)    NULL,
    [InstantWidth]               NUMERIC (18, 2)    NULL,
    [InstantHeight]              NUMERIC (18, 2)    NULL,
    [InstantDepth]               NUMERIC (18, 2)    NULL,
    [InstantDiameter]            NUMERIC (18, 2)    NULL,
    [InstantCostPrice]           NUMERIC (18, 2)    NULL,
    [ReadyToDeliveredDate]       DATE               NULL,
    [DefaultProductVendorId]     BIGINT             NULL,
    [InteriorCommission]         NUMERIC (18, 2)    DEFAULT ((0)) NULL,
    [SalesmanCommission]         NUMERIC (18, 2)    DEFAULT ((0)) NULL,
    CONSTRAINT [PK__Archive_OrderSet__CA2F7B240FCF7D07] PRIMARY KEY CLUSTERED ([Archive_OrderSetItemId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_Archive_OrderSetItems_cover]
    ON [dbo].[Archive_OrderSetItems20260128]([OrderId] ASC)
    INCLUDE([VersionId]) WITH (FILLFACTOR = 70);


GO

