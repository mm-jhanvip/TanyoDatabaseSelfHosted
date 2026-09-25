CREATE TABLE [dbo].[FeedbackQuestions] (
    [FeedbackQuestionId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [QuestionTitle]      VARCHAR (100)      NOT NULL,
    [TenantId]           INT                NOT NULL,
    [IsDeleted]          BIT                NOT NULL,
    [CreatedBy]          BIGINT             NOT NULL,
    [CreatedDate]        DATETIMEOFFSET (7) NOT NULL,
    [CreatedUTCDate]     DATETIME           NOT NULL,
    [UpdatedBy]          INT                NULL,
    [UpdatedDate]        DATETIMEOFFSET (7) NULL,
    [UpdatedUTCDate]     DATETIME           NULL,
    CONSTRAINT [PK__Feedback__139102A6247A1000] PRIMARY KEY CLUSTERED ([FeedbackQuestionId] ASC) WITH (FILLFACTOR = 80)
);


GO

