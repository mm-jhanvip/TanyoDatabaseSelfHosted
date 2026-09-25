CREATE TABLE [dbo].[City] (
    [CityId]         INT                IDENTITY (1, 1) NOT NULL,
    [CityName]       VARCHAR (512)      NOT NULL,
    [StateId]        INT                NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF_City_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_City_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_City_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([CityId] ASC)
);


GO

