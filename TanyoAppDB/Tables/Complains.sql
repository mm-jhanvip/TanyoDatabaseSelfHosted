CREATE TABLE [dbo].[Complains] (
    [ComplainId]        BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]           BIGINT             NULL,
    [ComplainKey]       VARCHAR (50)       NOT NULL,
    [Title]             VARCHAR (500)      NOT NULL,
    [Description]       VARCHAR (MAX)      NOT NULL,
    [Status]            INT                DEFAULT ((0)) NOT NULL,
    [CreatedBy]         BIGINT             NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         BIGINT             NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL,
    [OrderSetItemId]    BIGINT             NULL,
    [CustomerId]        BIGINT             NOT NULL,
    [TenantId]          INT                NOT NULL,
    [IsFree]            BIT                DEFAULT ((1)) NOT NULL,
    [SalesmanId]        BIGINT             NULL,
    [Address]           VARCHAR (MAX)      NULL,
    [Priority]          INT                NULL,
    [CustomerAddressId] BIGINT             NULL,
    CONSTRAINT [PK__Complain__88D54911DD604E8F] PRIMARY KEY CLUSTERED ([ComplainId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_Complains_OrderId_Status_CreatedBy_OrdersetItemId_CustomerId_TenantId]
    ON [dbo].[Complains]([OrderId] ASC, [Status] ASC, [CreatedBy] ASC, [OrderSetItemId] ASC, [CustomerId] ASC, [TenantId] ASC);


GO

