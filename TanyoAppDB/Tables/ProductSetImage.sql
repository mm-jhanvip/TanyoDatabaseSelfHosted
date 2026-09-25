CREATE TABLE [dbo].[ProductSetImage] (
    [ProductSetImageID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductSetId]      BIGINT             NOT NULL,
    [ImageName]         VARCHAR (MAX)      NULL,
    [IsCover]           BIT                CONSTRAINT [DF_ProductSetImage_IsCover] DEFAULT ((0)) NOT NULL,
    [ImagePath]         VARCHAR (MAX)      NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) CONSTRAINT [DF_ProductSetImage_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate]    DATETIME           CONSTRAINT [DF_ProductSetImage_CreatedUTCDate] DEFAULT (getutcdate()) NOT NULL,
    [IsVideo]           BIT                CONSTRAINT [DF_ProductSetImage_IsVideo] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ProductSetImage] PRIMARY KEY CLUSTERED ([ProductSetImageID] ASC)
);


GO

