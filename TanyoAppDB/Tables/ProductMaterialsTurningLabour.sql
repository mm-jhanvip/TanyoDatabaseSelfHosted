CREATE TABLE [dbo].[ProductMaterialsTurningLabour] (
    [Amount]            NUMERIC (10, 2)    NULL,
    [ProductMaterialID] BIGINT             NOT NULL,
    [ProductId]         BIGINT             NOT NULL,
    [SubjectTypeId]     INT                NOT NULL,
    [SubjectId]         INT                NOT NULL,
    [Qty]               NUMERIC (18, 2)    NOT NULL,
    [CreatedBy]         INT                NOT NULL,
    [CreatedDate]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]    DATETIME           NOT NULL,
    [UpdatedBy]         INT                NULL,
    [UpdatedDate]       DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]    DATETIME           NULL
);


GO

