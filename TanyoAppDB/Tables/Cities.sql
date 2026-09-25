CREATE TABLE [dbo].[Cities] (
    [CityID]   BIGINT       IDENTITY (1, 1) NOT NULL,
    [StateID]  BIGINT       NOT NULL,
    [CityName] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([CityID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Cities_StateID]
    ON [dbo].[Cities]([StateID] ASC) WITH (FILLFACTOR = 70);


GO

