CREATE TABLE [dbo].[CustomerAddresses] (
    [CustomerAddressId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]        BIGINT             NOT NULL,
    [AddressType]       VARCHAR (50)       NOT NULL,
    [Street1]           VARCHAR (200)      NOT NULL,
    [Street2]           VARCHAR (200)      NULL,
    [Landmark]          VARCHAR (100)      NULL,
    [Area]              VARCHAR (100)      NULL,
    [City]              VARCHAR (100)      NOT NULL,
    [State]             VARCHAR (100)      NOT NULL,
    [ZipCode]           VARCHAR (6)        NOT NULL,
    [IsDefault]         BIT                CONSTRAINT [DF__CustomerA__IsDef__2F650636] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT                CONSTRAINT [DF__CustomerA__IsDel__30592A6F] DEFAULT ((0)) NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) CONSTRAINT [DF__CustomerA__Creat__314D4EA8] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           CONSTRAINT [DF__CustomerA__Creat__324172E1] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    [OtherAddressType]  VARCHAR (20)       NULL,
    [Latitude]          VARCHAR (25)       NULL,
    [Longitude]         VARCHAR (25)       NULL,
    [CompanyName]       VARCHAR (100)      NULL,
    [GSTNo]             VARCHAR (15)       NULL,
    [Country]           VARCHAR (MAX)      NULL,
    [FullAddress]       VARCHAR (MAX)      NULL,
    CONSTRAINT [PK__Customer__ABD2CD0E8A5478E0] PRIMARY KEY CLUSTERED ([CustomerAddressId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_CustomerAddresses_CustomerId_IsDefault_Isdeleted_CreatedBy]
    ON [dbo].[CustomerAddresses]([CustomerId] ASC, [IsDefault] ASC, [IsDeleted] ASC, [CreatedBy] ASC);


GO

