CREATE TABLE [dbo].[ProductVendorMapping] (
    [ProductVendorMappingId] BIGINT                                               IDENTITY (1, 1) NOT NULL,
    [ProductId]              BIGINT                                               NOT NULL,
    [VendorId]               BIGINT                                               NOT NULL,
    [IsDefault]              BIT                                                  NOT NULL,
    [VendorProductId]        BIGINT                                               NULL,
    [IsDeleted]              BIT                                                  DEFAULT ((0)) NOT NULL,
    [CreatedBy]              BIGINT                                               NULL,
    [CreatedDate]            DATETIME                                             DEFAULT (getdate()) NOT NULL,
    [CreatedUTCDate]         DATETIME                                             DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              BIGINT                                               NULL,
    [UpdatedDate]            DATETIME                                             NULL,
    [UpdatedUTCDate]         DATETIME                                             NULL,
    [VendorModelNo]          VARCHAR (50)                                         NULL,
    [VendorProductPrice]     NUMERIC (18, 2) NULL,
    CONSTRAINT [PK_ProductVendorMapping] PRIMARY KEY CLUSTERED ([ProductVendorMappingId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_NC_ProductVendorMapping_Cover]
    ON [dbo].[ProductVendorMapping]([ProductId] ASC, [VendorId] ASC)
    INCLUDE([IsDefault]) WITH (FILLFACTOR = 70);


GO

