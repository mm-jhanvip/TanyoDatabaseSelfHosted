CREATE TABLE [dbo].[OrderFamily] (
    [OrderFamilyId]  BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustFamilyId]   BIGINT             NOT NULL,
    [OrderId]        BIGINT             NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF_OrderFamily_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF_OrderFamily_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([OrderFamilyId] ASC)
);


GO

