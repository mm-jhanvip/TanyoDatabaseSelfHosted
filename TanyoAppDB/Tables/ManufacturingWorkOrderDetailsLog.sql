CREATE TABLE [dbo].[ManufacturingWorkOrderDetailsLog] (
    [ManufacturingWorkOrderDetailsLogId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ManufacturingWorkOrderDetailId]     BIGINT             NOT NULL,
    [RawMaterialId]                      BIGINT             NOT NULL,
    [Description]                        VARCHAR (500)      NOT NULL,
    [ProvidedQty]                        NUMERIC (18, 2)    NOT NULL,
    [MaterialProviderId]                 BIGINT             NOT NULL,
    [MaterialReceiveId]                  BIGINT             NOT NULL,
    [CreatedBy]                          INT                NOT NULL,
    [CreatedDate]                        DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                     DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ManufacturingWorkOrderDetailsLogId] ASC)
);


GO

