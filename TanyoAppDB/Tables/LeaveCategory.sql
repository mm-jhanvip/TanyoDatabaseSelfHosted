CREATE TABLE [dbo].[LeaveCategory] (
    [LeaveCategoryID] INT                IDENTITY (1, 1) NOT NULL,
    [TenantId]        INT                NOT NULL,
    [Name]            VARCHAR (50)       NOT NULL,
    [IsPaid]          BIT                NOT NULL,
    [IsActive]        BIT                CONSTRAINT [DF__LeaveCate__IsAct__32AD1DE3] DEFAULT ((1)) NOT NULL,
    [CreatedBy]       INT                NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) CONSTRAINT [DF__LeaveCate__Creat__33A1421C] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]  DATETIME           CONSTRAINT [DF__LeaveCate__Creat__34956655] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       INT                NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    CONSTRAINT [PK__LeaveCat__3214EC27E2E55A10] PRIMARY KEY CLUSTERED ([LeaveCategoryID] ASC)
);


GO

