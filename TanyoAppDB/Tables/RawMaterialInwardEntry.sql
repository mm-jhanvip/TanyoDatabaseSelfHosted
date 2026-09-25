CREATE TABLE [dbo].[RawMaterialInwardEntry] (
    [InwardId]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [InwardEntryNumber] VARCHAR (20)       NOT NULL,
    [VendorId]          BIGINT             NOT NULL,
    [InwardType]        INT                DEFAULT ((1)) NULL,
    [PoNumber]          VARCHAR (20)       NULL,
    [TenantId]          INT                NOT NULL,
    [IsDeleted]         BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    [PORawMaterialId]   BIGINT             NULL,
    PRIMARY KEY CLUSTERED ([InwardId] ASC)
);


GO

