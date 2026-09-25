CREATE TABLE [dbo].[TrainingModuleVideo] (
    [TrainingModuleVideoId]   INT                IDENTITY (1, 1) NOT NULL,
    [TrainingModuleId]        INT                NOT NULL,
    [TrainingModuleVIdeoUrl]  VARCHAR (MAX)      NOT NULL,
    [TrainingModuleVideoName] VARCHAR (1024)     NOT NULL,
    [VideoDisplayOrder]       INT                NOT NULL,
    [IsDeleted]               BIT                CONSTRAINT [DF_TrainingModuleVideo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]               INT                NOT NULL,
    [CreatedDate]             DATETIMEOFFSET (7) CONSTRAINT [DF_TrainingModuleVideo_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]          DATETIME           CONSTRAINT [DF_TrainingModuleVideo_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               BIGINT             NULL,
    [UpdatedDate]             DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]          DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([TrainingModuleVideoId] ASC)
);


GO

