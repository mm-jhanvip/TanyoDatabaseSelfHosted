CREATE TABLE [dbo].[DeletedOrderSetItemsWithoutParent] (
    [OrderSetItemId]       BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]              BIGINT             NOT NULL,
    [OrderSetId]           BIGINT             NOT NULL,
    [DeliveryNo]           VARCHAR (50)       NULL,
    [SubjectTypeId]        INT                NOT NULL,
    [SubjectId]            BIGINT             NOT NULL,
    [ProductImage]         VARCHAR (MAX)      NULL,
    [Width]                NUMERIC (5, 2)     NULL,
    [Height]               NUMERIC (5, 2)     NULL,
    [Depth]                NUMERIC (5, 2)     NULL,
    [Quantity]             NUMERIC (18, 2)    NOT NULL,
    [UnitPrice]            NUMERIC (18, 2)    NOT NULL,
    [DiscountPrice]        NUMERIC (18, 2)    NOT NULL,
    [TotalAmount]          NUMERIC (18, 2)    NOT NULL,
    [Comment]              NVARCHAR (MAX)     NULL,
    [ItemStatus]           INT                NOT NULL,
    [CreatedBy]            INT                NOT NULL,
    [CreatedDate]          DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]       DATETIME           NOT NULL,
    [UpdatedBy]            INT                NULL,
    [UpdatedDate]          DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]       DATETIME           NULL,
    [ReceiveDate]          DATETIMEOFFSET (7) NULL,
    [ProvidedMaterial]     NUMERIC (5, 2)     NULL,
    [Diameter]             NUMERIC (5, 2)     NULL,
    [ParentOrderSetItemId] BIGINT             NULL,
    [DeliveryDate]         DATE               NULL,
    [AmountBeforeGST]      DECIMAL (18, 2)    NULL,
    [CGSTAmount]           DECIMAL (18, 2)    NULL,
    [SGSTAmount]           DECIMAL (18, 2)    NULL
);


GO

