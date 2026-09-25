CREATE TABLE [dbo].[Polish] (
    [PolishId]       INT                                                 IDENTITY (1, 1) NOT NULL,
    [Title]          VARCHAR (150)                                       NOT NULL,
    [ModelNo]        VARCHAR (50)                                        NOT NULL,
    [CompanyId]      INT                                                 NULL,
    [UnitId]         INT                                                 NOT NULL,
    [UnitPrice]      NUMERIC (8, 2) NOT NULL,
    [ImagePath]      VARCHAR (500)                                       NULL,
    [TenantId]       INT                                                 NOT NULL,
    [IsDeleted]      BIT                                                 DEFAULT ((0)) NOT NULL,
    [CreatedBy]      INT                                                 NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7)                                  CONSTRAINT [DF__Polish__CreatedD__056ECC6A] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME                                            DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                                                 NULL,
    [UpdatedDate]    DATETIMEOFFSET (7)                                  NULL,
    [UpdatedUTCDate] DATETIME                                            NULL,
    [GST]            NUMERIC (18, 2)                                     DEFAULT ((18)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PolishId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Polish_CompanyId_IsDeleted]
    ON [dbo].[Polish]([CompanyId] ASC, [IsDeleted] ASC)
    INCLUDE([ModelNo], [UnitId], [UnitPrice], [ImagePath], [CreatedDate], [GST]) WITH (FILLFACTOR = 70);


GO

