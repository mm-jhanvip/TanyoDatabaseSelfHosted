CREATE TABLE [dbo].[FeedbackOrders] (
    [FeedbackOrderId]    BIGINT             IDENTITY (1, 1) NOT NULL,
    [FeedbackQuestionId] INT                NOT NULL,
    [OrderId]            BIGINT             NOT NULL,
    [FeedbackValue]      INT                NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]     DATETIME           NOT NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    [TenantId]           INT                NOT NULL,
    PRIMARY KEY CLUSTERED ([FeedbackOrderId] ASC) WITH (FILLFACTOR = 80)
);


GO

