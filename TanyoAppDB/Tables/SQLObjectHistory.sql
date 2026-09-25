CREATE TABLE [dbo].[SQLObjectHistory] (
    [EventType]    NVARCHAR (MAX) NULL,
    [SchemaName]   NVARCHAR (MAX) NULL,
    [ObjectName]   NVARCHAR (MAX) NULL,
    [ObjectType]   NVARCHAR (MAX) NULL,
    [EventDate]    DATETIME       NULL,
    [SystemUser]   VARCHAR (100)  NULL,
    [CurrentUser]  VARCHAR (100)  NULL,
    [OriginalUser] VARCHAR (100)  NULL,
    [DatabaseName] VARCHAR (100)  NULL,
    [tsqlcode]     NVARCHAR (MAX) NULL,
    [EventData]    XML            NULL,
    [HostName]     VARCHAR (50)   DEFAULT (host_name()) NULL
);


GO

