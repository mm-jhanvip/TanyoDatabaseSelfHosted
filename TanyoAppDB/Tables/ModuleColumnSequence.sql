CREATE TABLE [dbo].[ModuleColumnSequence] (
    [ModuleColumnSequenceId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [UserId]                 BIGINT             NOT NULL,
    [ColumnSequence]         NVARCHAR (MAX)     NOT NULL,
    [CreatedDate]            DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]         DATETIME           NOT NULL,
    [UpdatedDate]            DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]         DATETIME           NULL,
    [ModuleName]             NVARCHAR (50)      NULL,
    CONSTRAINT [PK_ModuleColumnSequence] PRIMARY KEY CLUSTERED ([ModuleColumnSequenceId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_ModuleColumnSequence_cover]
    ON [dbo].[ModuleColumnSequence]([UserId] ASC, [ModuleName] ASC) WITH (FILLFACTOR = 70);


GO

