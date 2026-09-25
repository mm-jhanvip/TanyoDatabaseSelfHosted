CREATE TABLE [dbo].[Pincodes] (
    [PincodeId] BIGINT IDENTITY (1, 1) NOT NULL,
    [CityId]    BIGINT NOT NULL,
    [StateId]   BIGINT NOT NULL,
    [Pincode]   INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([PincodeId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_Pincodes_CityId_StateId]
    ON [dbo].[Pincodes]([CityId] ASC, [StateId] ASC);


GO

