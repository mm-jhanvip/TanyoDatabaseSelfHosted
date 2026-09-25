CREATE TABLE [dbo].[WhatsAppTemplates] (
    [TemplateId]      BIGINT             IDENTITY (1, 1) NOT NULL,
    [WpTemplateId]    VARCHAR (50)       NULL,
    [TemplateName]    VARCHAR (512)      NULL,
    [Category]        VARCHAR (10)       NULL,
    [TenantId]        BIGINT             NULL,
    [Language]        VARCHAR (5)        DEFAULT ('en_US') NULL,
    [Components]      NVARCHAR (MAX)     NULL,
    [Status]          VARCHAR (10)       NULL,
    [RejectionReason] VARCHAR (250)      NULL,
    [IsDeleted]       BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]       BIGINT             NOT NULL,
    [CreatedDate]     DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]  DATETIME           NOT NULL,
    [UpdatedBy]       BIGINT             NULL,
    [UpdatedDate]     DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]  DATETIME           NULL,
    [MessageFormat]   VARCHAR (10)       NULL,
    [ImageURL]        VARCHAR (MAX)      NULL,
    [ApprovedDate]    DATETIMEOFFSET (7) NULL,
    [FileName]        VARCHAR (50)       DEFAULT (NULL) NULL,
    PRIMARY KEY CLUSTERED ([TemplateId] ASC) WITH (FILLFACTOR = 80)
);


GO

