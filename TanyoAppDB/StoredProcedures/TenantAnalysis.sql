CREATE PROC [dbo].[TenantAnalysis]
WITH ENCRYPTION
AS
BEGIN TRY
	DECLARE @EndDate AS DATE = GETDATE()
	DECLARE @StartDate AS DATE = GETDATE() - 7

	SELECT t.TenantID
		,t.TenantName
		,(
			SELECT COUNT(1)
			FROM Products p
			WHERE p.TenantId = t.TenantId
				AND p.CreatedDate BETWEEN @StartDate
					AND @EndDate
			) AS NosOfProductsAdded
		,(
			SELECT COUNT(1)
			FROM Orders o
			WHERE o.TenantId = t.TenantId
				AND o.CreatedDate BETWEEN @StartDate
					AND @EndDate
			) AS NosOfOrdersAdded
	FROM Tenants t
	WHERE t.IsDemo = 0
		AND t.IsDeleted = 0
	ORDER BY 3 DESC
END TRY

BEGIN CATCH
	DECLARE @ObjectName VARCHAR(500)
		,@ErrorMsg VARCHAR(MAX);

	SET @ObjectName = OBJECT_NAME(@@PROCID);
	SET @ErrorMsg = ERROR_MESSAGE();

	EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
		,@ErrorMsg = @ErrorMsg;
END CATCH

GO

