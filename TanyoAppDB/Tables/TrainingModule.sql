CREATE TABLE [dbo].[TrainingModule] (
    [TrainingModuleId]   INT                IDENTITY (1, 1) NOT NULL,
    [TrainingModuleName] VARCHAR (1024)     NOT NULL,
    [ModuleDisplayOrder] INT                NOT NULL,
    [IsDeleted]          BIT                CONSTRAINT [DF_TrainingModule_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]          INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) CONSTRAINT [DF_TrainingModule_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]     DATETIME           CONSTRAINT [DF_TrainingModule_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]          BIGINT             NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([TrainingModuleId] ASC)
);


GO

