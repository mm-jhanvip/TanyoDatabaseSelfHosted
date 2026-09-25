CREATE TABLE [dbo].[POProductItemsAttachments] (
    [POProductItemsAttachmentId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [POProductItemId]            BIGINT             NOT NULL,
    [FileURL]                    VARCHAR (MAX)      NOT NULL,
    [IsDeleted]                  BIT                CONSTRAINT [DF_POProductItemsAttachments_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsImage]                    BIT                CONSTRAINT [DF_POProductItemsAttachments_IsImage] DEFAULT ((0)) NOT NULL,
    [CreatedBy]                  INT                NOT NULL,
    [CreatedDate]                DATETIMEOFFSET (7) CONSTRAINT [DF_POProductItemsAttachments_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]             DATETIME           CONSTRAINT [DF_POProductItemsAttachments_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [LastModifiedBy]             BIGINT             NULL,
    [LastModifiedDate]           DATETIMEOFFSET (7) NULL,
    [LastModifiedUTCDate]        DATETIME           NULL,
    PRIMARY KEY CLUSTERED ([POProductItemsAttachmentId] ASC)
);


GO

