CREATE TABLE [dbo].[ProductImages] (
    [ProductImageID] BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]      BIGINT             NOT NULL,
    [ImageName]      VARCHAR (MAX)      NOT NULL,
    [IsCover]        BIT                CONSTRAINT [DF__ProductIm__IsCov__6C390A4C] DEFAULT ((0)) NOT NULL,
    [ImagePath]      VARCHAR (MAX)      NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__ProductIm__Creat__3EA749C6] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__ProductIm__Creat__3F9B6DFF] DEFAULT (getutcdate()) NOT NULL,
    [IsVideo]        BIT                CONSTRAINT [DF__ProductIm__IsVid__77EAB41A] DEFAULT ((0)) NOT NULL,
    [IsProcessed]    BIT                DEFAULT ((0)) NOT NULL,
    [ImageColorCode] VARCHAR (15)       NULL,
    CONSTRAINT [PK__ProductI__07B2B1D8D71A5719] PRIMARY KEY CLUSTERED ([ProductImageID] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ProductImages_ProductId_IsCover]
    ON [dbo].[ProductImages]([ProductId] ASC, [IsCover] ASC, [CreatedUTCDate] ASC)
    INCLUDE([ImagePath]) WITH (FILLFACTOR = 80);


GO

