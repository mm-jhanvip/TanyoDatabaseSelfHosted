CREATE TABLE [dbo].[DBErrorLogs] (
    [DBErrorLogID]  INT            IDENTITY (1, 1) NOT NULL,
    [ObjectName]    VARCHAR (1000) NOT NULL,
    [ErrorMessage]  VARCHAR (MAX)  NULL,
    [ErrorDateTime] DATETIME       CONSTRAINT [DF_DBErrorLogs_ErrorDateTime] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_DBErrorLogs] PRIMARY KEY CLUSTERED ([DBErrorLogID] ASC)
);


GO

