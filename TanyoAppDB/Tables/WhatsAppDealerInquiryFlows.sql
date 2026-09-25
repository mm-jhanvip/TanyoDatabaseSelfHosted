CREATE TABLE [dbo].[WhatsAppDealerInquiryFlows] (
    [WhatsAppDealerInquiryFlowId] BIGINT             IDENTITY (1, 1) NOT NULL,
    [MobileNo]                    VARCHAR (20)       NOT NULL,
    [DealerCustomerId]            BIGINT             NOT NULL,
    [CurrentStep]                 INT                CONSTRAINT [DF_WhatsAppDealerInquiryFlows_CurrentStep] DEFAULT ((1)) NOT NULL,
    [SelectedModelNo]             VARCHAR (100)      NULL,
    [SelectedProductId]           BIGINT             NULL,
    [TenantId]                    INT                NOT NULL,
    [IsActive]                    BIT                CONSTRAINT [DF_WhatsAppDealerInquiryFlows_IsActive] DEFAULT ((1)) NOT NULL,
    [CreatedDate]                 DATETIMEOFFSET (7) CONSTRAINT [DF_WhatsAppDealerInquiryFlows_CreatedDate] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [UpdatedDate]                 DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_WhatsAppDealerInquiryFlows] PRIMARY KEY CLUSTERED ([WhatsAppDealerInquiryFlowId] ASC)
);


GO

CREATE NONCLUSTERED INDEX [IX_WhatsAppDealerInquiryFlows_MobileNo_TenantId_IsActive]
    ON [dbo].[WhatsAppDealerInquiryFlows]([MobileNo] ASC, [TenantId] ASC, [IsActive] ASC)
    INCLUDE([DealerCustomerId], [CurrentStep], [SelectedModelNo], [SelectedProductId]);


GO

