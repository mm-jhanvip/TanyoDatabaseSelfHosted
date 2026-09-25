CREATE TABLE [dbo].[State] (
    [StateId]        INT                IDENTITY (1, 1) NOT NULL,
    [StateName]      VARCHAR (512)      NOT NULL,
    [IsDeleted]      BIT                CONSTRAINT [DF_State_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_State_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_State_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([StateId] ASC)
);


GO

