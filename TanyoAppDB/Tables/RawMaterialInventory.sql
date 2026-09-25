CREATE TABLE [dbo].[RawMaterialInventory] (
    [RawMaterialInventoryId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [RawMaterialId]          BIGINT             NOT NULL,
    [InventoryDate]          DATE               NOT NULL,
    [Inventory]              INT                NOT NULL,
    [MinimumLimit]           INT                DEFAULT ((0)) NOT NULL,
    [LastModifiedBy]         BIGINT             NOT NULL,
    [LastModifiedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([RawMaterialInventoryId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_RawMaterialInventory_RawMaterialId_LastModifiedDate]
    ON [dbo].[RawMaterialInventory]([RawMaterialId] ASC, [LastModifiedDate] ASC)
    INCLUDE([Inventory], [MinimumLimit], [LastModifiedBy]) WITH (FILLFACTOR = 70);


GO

