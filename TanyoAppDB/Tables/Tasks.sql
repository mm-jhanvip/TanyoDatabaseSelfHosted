CREATE TABLE [dbo].[Tasks] (
    [TaskId]         BIGINT             IDENTITY (1, 1) NOT NULL,
    [Title]          VARCHAR (500)      NOT NULL,
    [Description]    VARCHAR (MAX)      NULL,
    [CustomerId]     BIGINT             NOT NULL,
    [CategoryId]     BIGINT             NULL,
    [Priority]       INT                NOT NULL,
    [StatusId]       BIGINT             NOT NULL,
    [AssignTo]       BIGINT             NOT NULL,
    [StartDate]      DATE               NOT NULL,
    [DueDate]        DATE               NOT NULL,
    [WorkType]       INT                NOT NULL,
    [EstimatedHours] VARCHAR (10)       NOT NULL,
    [IsPrivate]      BIT                DEFAULT ((0)) NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [TenantId]       BIGINT             NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([TaskId] ASC)
);


GO

