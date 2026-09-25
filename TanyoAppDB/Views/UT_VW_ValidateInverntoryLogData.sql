CREATE VIEW [dbo].[UT_VW_ValidateInverntoryLogData]
WITH ENCRYPTION
AS
SELECT AL.*
FROM ActivityLogs AL WITH (NOLOCK)
INNER JOIN SubjectTypes ST WITH (NOLOCK) ON AL.SubjectTypeId = ST.SubjectTypeId
WHERE ST.SubjectTypeName = 'ProductQuantity'
AND CAST(AL.CreatedDate AS DATE) > '2026-03-02'

GO

