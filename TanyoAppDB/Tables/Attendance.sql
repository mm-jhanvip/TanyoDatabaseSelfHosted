CREATE TABLE [dbo].[Attendance] (
    [AttendanceId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [UserId]         BIGINT             NOT NULL,
    [StartDate]      DATETIME           NOT NULL,
    [EndDate]        DATETIME           NULL,
    [Type]           BIT                NOT NULL,
    [IsManual]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    [InLatitude]     VARCHAR (50)       NULL,
    [InLongitude]    VARCHAR (50)       NULL,
    [OutLatitude]    VARCHAR (50)       NULL,
    [OutLongitude]   VARCHAR (50)       NULL,
    PRIMARY KEY CLUSTERED ([AttendanceId] ASC) WITH (FILLFACTOR = 80)
);


GO

