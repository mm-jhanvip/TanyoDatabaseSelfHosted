CREATE TABLE [dbo].[ComplainRemarks] (
    [ComplainRemarkId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ComplainId]       BIGINT             NOT NULL,
    [Status]           INT                DEFAULT ((0)) NOT NULL,
    [Remark]           NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]        BIGINT             NOT NULL,
    [CreatedDate]      DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]   DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ComplainRemarkId] ASC)
);


GO

