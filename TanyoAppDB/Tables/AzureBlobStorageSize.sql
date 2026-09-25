CREATE TABLE [dbo].[AzureBlobStorageSize] (
    [ID]                  INT                IDENTITY (1, 1) NOT NULL,
    [TenantID]            BIGINT             NOT NULL,
    [FolderPath]          VARCHAR (100)      NOT NULL,
    [FolderSizeKB]        VARCHAR (100)      NOT NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

