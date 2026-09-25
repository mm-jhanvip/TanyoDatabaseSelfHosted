CREATE TABLE [dbo].[ProductQuantities] (
    [ProductQuantityId]   BIGINT             IDENTITY (1, 1) NOT NULL,
    [ProductId]           BIGINT             NOT NULL,
    [QuantityDate]        DATETIMEOFFSET (7) NOT NULL,
    [Quantity]            NUMERIC (18, 2)    NOT NULL,
    [LastModifiedBy]      BIGINT             NOT NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) CONSTRAINT [DF__ProductQu__LastM__0F4D3C5F] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [MinimumLimit]        INT                DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ProductQuantityId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_ProductQuantities_ProductId_LastModifiedDate]
    ON [dbo].[ProductQuantities]([ProductId] ASC, [LastModifiedDate] ASC)
    INCLUDE([QuantityDate], [Quantity], [LastModifiedBy], [MinimumLimit]) WITH (FILLFACTOR = 80);


GO

CREATE TRIGGER [dbo].[TRG_ProductQuantities_Log] ON [dbo].[ProductQuantities] 
AFTER INSERT
	,UPDATE
	,DELETE
AS
BEGIN
	SET NOCOUNT ON;


	INSERT INTO TanyoLogs.dbo.ProductQuantitiesLog (
		ProductId
		,PreviousQuantity
		,NewQuantity
		,Action
		)
	SELECT COALESCE(I.ProductId, D.ProductId) AS ProductId
		,D.Quantity AS PreviousQuantity
		,I.Quantity AS NewQuantity
		,CASE 
			WHEN I.ProductId IS NOT NULL
				AND D.ProductId IS NULL
				THEN 'INSERT'
			WHEN I.ProductId IS NOT NULL
				AND D.ProductId IS NOT NULL
				THEN 'UPDATE'
			WHEN I.ProductId IS NULL
				AND D.ProductId IS NOT NULL
				THEN 'DELETE'
			END AS Action
	FROM INSERTED I
	FULL OUTER JOIN DELETED D ON I.ProductId = D.ProductId;
END;

GO

