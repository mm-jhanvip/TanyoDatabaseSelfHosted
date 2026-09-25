CREATE TABLE [dbo].[Holidays] (
    [HolidayID]      INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NOT NULL,
    [Name]           VARCHAR (50)       NOT NULL,
    [Date]           DATE               NOT NULL,
    [IsFloating]     BIT                NOT NULL,
    [IsActive]       BIT                CONSTRAINT [DF__Holidays__IsActi__19E17019] DEFAULT ((1)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Holidays__Create__1AD59452] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__Holidays__Create__1BC9B88B] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK__Holidays__3214EC27301DA4A3] PRIMARY KEY CLUSTERED ([HolidayID] ASC)
);


GO

