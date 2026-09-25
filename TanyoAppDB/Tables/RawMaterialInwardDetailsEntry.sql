CREATE TABLE [dbo].[RawMaterialInwardDetailsEntry] (
    [InwardDetailsId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [InwardId]        BIGINT             NOT NULL,
    [RawMaterialId]   INT                NOT NULL,
    [Quantity]        INT                NOT NULL,
    [WarehouseId]     BIGINT             NULL,
    [Remark]          NVARCHAR (MAX)     NULL,
    [ImagePath]       VARCHAR (MAX)      NULL,
    [AudioURL]        VARCHAR (MAX)      NULL,
    [IsDeleted]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([InwardDetailsId] ASC)
);


GO

