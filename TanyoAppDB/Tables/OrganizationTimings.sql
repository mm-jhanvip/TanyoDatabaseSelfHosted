CREATE TABLE [dbo].[OrganizationTimings] (
    [OrganizationTimingId] INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]             INT                NOT NULL,
    [DayOfWeek]            INT                NOT NULL,
    [StartTime]            TIME (7)           CONSTRAINT [DF_OrganizationTiming_StartTime] DEFAULT ('00:00:00') NOT NULL,
    [EndTime]              TIME (7)           CONSTRAINT [DF_OrganizationTiming_EndTime] DEFAULT ('23:59:59') NOT NULL,
    [IsEnabled]            BIT                DEFAULT ((1)) NOT NULL,
    [CreatedBy]            INT                NOT NULL,
    [CreatedDate]          DATETIMEOFFSET (7) CONSTRAINT [DF_OrgTiming_Created] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]       DATETIME           CONSTRAINT [DF_OrgTiming_CreatedUTC] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]            INT                NULL,
    [UpdatedDate]          DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]       DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([OrganizationTimingId] ASC)
);


GO

