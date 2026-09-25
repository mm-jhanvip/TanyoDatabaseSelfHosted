CREATE TABLE [dbo].[LocationUserMapping] (
    [LocationUserMappingID] BIGINT IDENTITY (1, 1) NOT NULL,
    [LocationID]            BIGINT NOT NULL,
    [UserID]                BIGINT NOT NULL,
    [IsDefault]             BIT    NOT NULL,
    PRIMARY KEY CLUSTERED ([LocationUserMappingID] ASC) WITH (FILLFACTOR = 80)
);


GO

