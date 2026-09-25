CREATE TABLE [dbo].[LeaveApplicationDetails] (
    [LeaveApplicationDetailID] BIGINT IDENTITY (1, 1) NOT NULL,
    [LeaveApplicationID]       BIGINT NOT NULL,
    [LeaveDate]                DATE   NOT NULL,
    [LeaveType]                INT    NOT NULL,
    PRIMARY KEY CLUSTERED ([LeaveApplicationDetailID] ASC)
);


GO

