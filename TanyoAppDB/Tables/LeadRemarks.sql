CREATE TABLE [dbo].[LeadRemarks] (
    [LeadRemarkId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [LeadId]         BIGINT             NOT NULL,
    [Status]         INT                DEFAULT ((0)) NOT NULL,
    [Remark]         NVARCHAR (MAX)     NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LeadRemarkId] ASC)
);


GO

