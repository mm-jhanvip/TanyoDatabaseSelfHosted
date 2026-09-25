CREATE TABLE [dbo].[Departments] (
    [DepartmentID]   INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]       INT                NOT NULL,
    [Name]           VARCHAR (50)       NOT NULL,
    [IsActive]       BIT                CONSTRAINT [DF__Departmen__IsAct__0C8774FB] DEFAULT ((1)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Departmen__Creat__0D7B9934] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__Departmen__Creat__0E6FBD6D] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK__Departme__3214EC27748253FB] PRIMARY KEY CLUSTERED ([DepartmentID] ASC)
);


GO

