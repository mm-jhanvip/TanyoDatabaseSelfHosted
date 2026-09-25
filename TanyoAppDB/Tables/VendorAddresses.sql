CREATE TABLE [dbo].[VendorAddresses] (
    [VendorAddressId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [VendorId]        BIGINT             NOT NULL,
    [StreetAddress1]  VARCHAR (200)      NOT NULL,
    [StreetAddress2]  VARCHAR (200)      NULL,
    [Landmark]        VARCHAR (100)      NULL,
    [City]            VARCHAR (100)      NOT NULL,
    [State]           VARCHAR (100)      NOT NULL,
    [Country]         VARCHAR (100)      NOT NULL,
    [Pincode]         VARCHAR (10)       NOT NULL,
    [IsDeleted]       BIT                NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]  DATETIME           NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [FullAddress]     VARCHAR (500)      NULL,
    CONSTRAINT [PK_VendorAddresses] PRIMARY KEY CLUSTERED ([VendorAddressId] ASC) WITH (FILLFACTOR = 80)
);


GO

