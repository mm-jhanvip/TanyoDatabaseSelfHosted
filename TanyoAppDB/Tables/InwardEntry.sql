CREATE TABLE [dbo].[InwardEntry] (
    [InwardId]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT             NOT NULL,
    [TenantId]          INT                NOT NULL,
    [PoNumber]          VARCHAR (20)       NULL,
    [InwardEntryNumber] VARCHAR (20)       NOT NULL,
    [IsDeleted]         BIT                NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]    DATETIME           NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    [InwardType]        INT                DEFAULT ((1)) NOT NULL,
    [OrderId]           BIGINT             NULL,
    [CustomerId]        BIGINT             NULL,
    [POProductId]       BIGINT             NULL,
    [StockTransferId]   INT                NULL,
    CONSTRAINT [PK_InwardEntry] PRIMARY KEY CLUSTERED ([InwardId] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [InwardType_ENUM] CHECK ([InwardType]>=(0) AND [InwardType]<=(4))
);


GO

CREATE NONCLUSTERED INDEX [NonClusteredIndex-20250905-185523]
    ON [dbo].[InwardEntry]([VendorId] ASC, [TenantId] ASC, [IsDeleted] ASC)
    INCLUDE([InwardId]);


GO

