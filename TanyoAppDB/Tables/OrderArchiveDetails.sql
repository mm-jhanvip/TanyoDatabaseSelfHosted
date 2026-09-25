CREATE TABLE [dbo].[OrderArchiveDetails] (
    [ID]             BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderID]        BIGINT             NOT NULL,
    [ReasonID]       BIGINT             NOT NULL,
    [ReasonText]     NVARCHAR (MAX)     NULL,
    [CreatedBy]      BIGINT             NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO

