CREATE TABLE [dbo].[AreaByPincode] (
    [AreaByPincodeId] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (40) NULL,
    [District]        VARCHAR (40) NULL,
    [Region]          VARCHAR (40) NULL,
    [State]           VARCHAR (20) NULL,
    [Country]         VARCHAR (20) NULL,
    [ZipCode]         VARCHAR (6)  NOT NULL,
    CONSTRAINT [PK_AreaByPincode] PRIMARY KEY CLUSTERED ([AreaByPincodeId] ASC) WITH (FILLFACTOR = 80)
);


GO

