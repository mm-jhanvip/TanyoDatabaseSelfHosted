CREATE TABLE [dbo].[ActivityLogs] (
    [ActivityLogID]  INT                IDENTITY (5828035, 1) NOT NULL,
    [SubjectTypeId]  INT                NULL,
    [SubjectId]      BIGINT             NULL,
    [Description]    VARCHAR (500)      NULL,
    [Action]         VARCHAR (10)       NULL,
    [CreatedBy]      INT                NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_ActivityLogs_CreatedDate] DEFAULT (sysdatetimeoffset()) NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_ActivityLogs_CreatedUTCDate] DEFAULT (getutcdate()) NULL,
    [Remarks]        NVARCHAR (1000)    NULL,
    [WarehouseId]    BIGINT             NULL,
    [OrderId]        BIGINT             NULL,
    [Quantity]       NUMERIC (18, 2)    NULL,
    CONSTRAINT [PK_ActivityLogs] PRIMARY KEY CLUSTERED ([ActivityLogID] ASC)
);


GO

