CREATE TABLE [dbo].[ManufacturingWorkOrderDetails] (
    [ManufacturingWorkOrderDetailId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ManufacturingWorkOrderId]       BIGINT             NOT NULL,
    [RawMaterialId]                  BIGINT             NOT NULL,
    [RequiredQty]                    NUMERIC (18, 2)    NULL,
    [ProvidedQty]                    NUMERIC (18, 2)    DEFAULT ((0)) NOT NULL,
    [CreatedBy]                      INT                NOT NULL,
    [CreatedDate]                    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                 DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                      BIGINT             NULL,
    [UpdatedDate]                    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]                 DATETIME           NULL,
    [IsNotNeeded]                    BIT                DEFAULT ((0)) NOT NULL,
    [IsFromBom]                      BIT                DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ManufacturingWorkOrderDetailId] ASC)
);


GO

