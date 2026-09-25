CREATE TABLE [dbo].[CustomerRemarks] (
    [CustomerRemarkId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [CustomerId]       BIGINT             NOT NULL,
    [Remark]           NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]        INT                NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([CustomerRemarkId] ASC)
);


GO

