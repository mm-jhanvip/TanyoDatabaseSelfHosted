CREATE TABLE [dbo].[POProductAttachments] (
    [POProductAttachmentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [POProductId]           BIGINT             NOT NULL,
    [FileURL]               NVARCHAR (MAX)     NOT NULL,
    [LastModifiedBy]        BIGINT             NOT NULL,
    [LastModifiedDate]      DATETIMEOFFSET (7) CONSTRAINT [DF_POProductAttachments_LastModifiedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate]   DATETIME           CONSTRAINT [DF_POProductAttachments_LastModifiedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [IsImage]               BIT                CONSTRAINT [DF_POProductAttachments_IsImage] DEFAULT ((0)) NOT NULL,
    [Status]                INT                NULL,
    PRIMARY KEY CLUSTERED ([POProductAttachmentId] ASC)
);


GO

