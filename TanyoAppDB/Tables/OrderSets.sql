CREATE TABLE [dbo].[OrderSets] (
    [OrderSetId]     BIGINT             IDENTITY (1, 1) NOT NULL,
    [OrderId]        BIGINT             NOT NULL,
    [SetName]        VARCHAR (100)      NOT NULL,
    [CreatedBy]      INT                NOT NULL,
    [CreatedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__OrderSets__Creat__77DFC722] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreatedUTCDate] DATETIME           CONSTRAINT [DF__OrderSets__Creat__78D3EB5B] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]      INT                NULL,
    [UpdatedDate]    DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate] DATETIME           NULL,
    [IsDeleted]      BIT                DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__OrderSet__F4D401595F7644F4] PRIMARY KEY CLUSTERED ([OrderSetId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [ix_NC_OrderSets_Cover]
    ON [dbo].[OrderSets]([OrderId] ASC);


GO

