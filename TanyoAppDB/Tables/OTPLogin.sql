CREATE TABLE [dbo].[OTPLogin] (
    [Id]          BIGINT             IDENTITY (1, 1) NOT NULL,
    [PhoneNumber] VARCHAR (10)       NOT NULL,
    [OTP]         VARCHAR (10)       NOT NULL,
    [ExpiryTime]  DATETIMEOFFSET (7) CONSTRAINT [DF__OTPLogin__Expiry__1293BD5E] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [EmailId]     VARCHAR (100)      NULL,
    CONSTRAINT [PK_OTPLogin] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_OTPLogin_OTP]
    ON [dbo].[OTPLogin]([Id] ASC, [OTP] ASC) WITH (FILLFACTOR = 70);


GO

