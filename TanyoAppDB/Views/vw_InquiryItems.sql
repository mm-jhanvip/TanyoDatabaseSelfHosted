
--SELECT * FROM vw_InquiryItems
CREATE VIEW [dbo].[vw_InquiryItems]
WITH ENCRYPTION
AS
		SELECT o.OrderId
			,o.TenantId
			,os.SubjectId
			,os.SubjectTypeId
			,os.Quantity
		FROM dbo.Orders o WITH (NOLOCK)
		INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
		WHERE os.IsDeleted = 0
		AND o.Status IN (0,1)

GO

