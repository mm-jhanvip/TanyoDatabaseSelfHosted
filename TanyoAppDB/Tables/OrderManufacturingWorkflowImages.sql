CREATE TABLE [dbo].[OrderManufacturingWorkflowImages] (
    [OrderManufacturingWorkflowImageId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderManufacturingWorkflowId]      BIGINT             NOT NULL,
    [DrawImage]                         VARCHAR (MAX)      NULL,
    [CreatedBy]                         INT                NOT NULL,
    [CreatedDate]                       DATETIMEOFFSET (7) CONSTRAINT [DF__OrderManu__Creat__66A02C87] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                    DATETIME           CONSTRAINT [DF__OrderManu__Creat__679450C0] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK__OrderMan__A04F301BD3D4EA37] PRIMARY KEY CLUSTERED ([OrderManufacturingWorkflowImageId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_OrderManufacturingWorkflowImages_OrderManufacturingWorkFlowId]
    ON [dbo].[OrderManufacturingWorkflowImages]([OrderManufacturingWorkflowId] ASC) WITH (FILLFACTOR = 70);


GO

