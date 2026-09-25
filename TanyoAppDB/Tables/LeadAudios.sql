CREATE TABLE [dbo].[LeadAudios] (
    [LeadAudioId]         BIGINT             IDENTITY (1, 1) NOT NULL,
    [LeadId]              BIGINT             NOT NULL,
    [AudioURL]            VARCHAR (MAX)      NOT NULL,
    [LastModifiedBy]      BIGINT             NOT NULL,
    [LastModifiedDate]    DATETIMEOFFSET (7) DEFAULT (sysdatetimeoffset()) NOT NULL,
    [LastModifiedUTCDate] DATETIME           DEFAULT (getutcdate()) NOT NULL,
    [IsImage]             BIT                DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([LeadAudioId] ASC) WITH (FILLFACTOR = 80)
);


GO

CREATE NONCLUSTERED INDEX [IX_LeadAudios_LeadId_LastModifiedBy]
    ON [dbo].[LeadAudios]([LeadId] ASC, [LastModifiedBy] ASC) WITH (FILLFACTOR = 70);


GO

