CREATE TABLE [dbo].[UserFavoriteMenu] (
    [UserFavoriteMenuId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [UserId]             INT                NOT NULL,
    [FavoriteMenuId]     INT                NOT NULL,
    [CreatedBy]          INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]     DATETIME           NOT NULL,
    PRIMARY KEY CLUSTERED ([UserFavoriteMenuId] ASC)
);


GO

