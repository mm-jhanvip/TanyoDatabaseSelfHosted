CREATE TABLE [dbo].[WhatsAppComplaintFlows] (
    [WhatsAppComplaintFlowID] BIGINT       IDENTITY (1, 1) NOT NULL,
    [MobileNo]                VARCHAR (20) NOT NULL,
    [CustomerId]              BIGINT       NOT NULL,
    [IsValid]                 BIT          DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([WhatsAppComplaintFlowID] ASC)
);


GO

