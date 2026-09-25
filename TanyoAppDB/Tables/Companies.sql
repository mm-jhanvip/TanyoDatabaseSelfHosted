CREATE TABLE [dbo].[Companies] (
    [CompanyId]      INT                IDENTITY (1, 1) NOT NULL,
    [CompanyName]    VARCHAR (100)      NOT NULL,
    [RSPPercentage]  NUMERIC (18, 2)    NOT NULL,
    [WSPPercentage]  NUMERIC (18, 2)    NOT NULL,
    [MaxDiscount]    NUMERIC (18, 2)    NOT NULL,
    [TenantId]       BIGINT             NOT NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      BIGINT             NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([CompanyId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Companies_TenantId_IsDeleted_CreatedBy]
    ON [dbo].[Companies]([TenantId] ASC, [IsDeleted] ASC, [CreatedBy] ASC) WITH (FILLFACTOR = 70);


GO

