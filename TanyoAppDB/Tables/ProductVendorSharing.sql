CREATE TABLE [dbo].[ProductVendorSharing] (
    [ID]             BIGINT   IDENTITY (1, 1) NOT NULL,
    [ProductID]      BIGINT   NOT NULL,
    [FromTenantsID]  INT      NOT NULL,
    [ToTenantID]     INT      NOT NULL,
    [Status]         INT      NOT NULL,
    [VendorId]       BIGINT   NOT NULL,
    [CreatedBy]      BIGINT   NOT NULL,
    [CreatedDate]    DATETIME NOT NULL,
    [CreatedUTCDate] DATETIME NOT NULL,
    [UpdatedBy]      BIGINT   NULL,
    [UpdatedDate]    DATETIME NULL,
    [UpdatedUTCDate] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

