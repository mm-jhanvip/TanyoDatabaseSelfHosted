CREATE TABLE [dbo].[Designations] (
    [DesignationID]  INT                IDENTITY (1, 1) NOT NULL,
    [DepartmentID]   INT                NOT NULL,
    [TenantId]       INT                NOT NULL,
    [Name]           VARCHAR (50)       NOT NULL,
    [IsActive]       BIT                CONSTRAINT [DF__Designati__IsAct__114C2A18] DEFAULT ((1)) NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__Designati__Creat__12404E51] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__Designati__Creat__1334728A] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    CONSTRAINT [PK__Designat__3214EC27FC200953] PRIMARY KEY CLUSTERED ([DesignationID] ASC)
);


GO

