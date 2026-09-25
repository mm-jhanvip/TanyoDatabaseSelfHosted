CREATE TABLE [dbo].[LeaveApplications] (
    [LeaveApplicationID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [UserID]             INT                NOT NULL,
    [LeaveCategoryID]    INT                NOT NULL,
    [StartDate]          DATE               NOT NULL,
    [EndDate]            DATE               NOT NULL,
    [NumberOfDays]       DECIMAL (4, 2)     NOT NULL,
    [Reason]             VARCHAR (500)      NOT NULL,
    [ApprovedBy]         INT                NULL,
    [ApprovedOn]         DATETIME           NULL,
    [ApproverComment]    VARCHAR (500)      NULL,
    [Status]             TINYINT            NOT NULL,
    [CreatedBy]          INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF__LeaveAppl__Creat__3B4263E4] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           NOT NULL,
    [UpdatedBy]          INT                NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    CONSTRAINT [PK__LeaveApp__3214EC272916E0E1] PRIMARY KEY CLUSTERED ([LeaveApplicationID] ASC)
);


GO

