CREATE TABLE [dbo].[OrganizationTimingUserMapping] (
    [OrganizationTimingUserMappingId] INT                IDENTITY (1, 1) NOT NULL,
    [UserId]                          INT                NOT NULL,
    [DayOfWeek]                       INT                NOT NULL,
    [StartTime]                       TIME (7)           CONSTRAINT [DF_OrgTimingUer_StartTime] DEFAULT ('00:00:00') NOT NULL,
    [EndTime]                         TIME (7)           CONSTRAINT [DF_OrgTimingUser_EndTime] DEFAULT ('23:59:59') NOT NULL,
    [IsEnabled]                       BIT                DEFAULT ((1)) NOT NULL,
    [CreatedBy]                       INT                NOT NULL,
    [CreatedDate]                     DATETIMEOFFSET (7) CONSTRAINT [DF_OrgTimingUser_Created] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]                  DATETIME           CONSTRAINT [DF_OrgTimingUser_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                       INT                NULL,
    [UpdatedDate]                     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]                  DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([OrganizationTimingUserMappingId] ASC)
);


GO

