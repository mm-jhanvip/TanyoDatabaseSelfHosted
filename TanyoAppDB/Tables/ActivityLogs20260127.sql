CREATE TABLE [dbo].[ActivityLogs20260127] (
    [ActivityLogID]  INT                IDENTITY (1, 1) NOT NULL,
    [SubjectTypeId]  INT                NOT NULL,
    [SubjectId]      BIGINT             NOT NULL,
    [Description]    VARCHAR (500)      NOT NULL,
    [Action]         VARCHAR (10)       NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__ActivityL__Creat__6A50C1DA] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__ActivityL__Creat__6B44E613] DEFAULT (getutcdate()) NOT NULL,
    [Remarks]        NVARCHAR (500)     NULL,
    [WarehouseId]    BIGINT             NULL,
    [OrderId]        BIGINT             NULL,
    [Quantity]       BIGINT             NULL,
    CONSTRAINT [PK__Activity__19A9B78F1880B1A0] PRIMARY KEY CLUSTERED ([ActivityLogID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ActivityLogs_SubjectTypeId_SubjectId]
    ON [dbo].[ActivityLogs20260127]([SubjectTypeId] ASC, [SubjectId] ASC) WITH (FILLFACTOR = 80);


GO

