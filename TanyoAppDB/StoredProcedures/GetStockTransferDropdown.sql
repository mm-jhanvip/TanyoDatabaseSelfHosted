-- =============================================
-- Description : Get Stock Transfer dropdown list by TenantId with optional Stock Transfer No search.
--               Returns only Stock Transfers with In-Transit status.
-- =============================================
/*
	EXEC [dbo].[GetStockTransferDropdown]
		@TenantId = 2
		,@Search = NULL
*/
CREATE   PROCEDURE [dbo].[GetStockTransferDropdown]
(
	@TenantId INT
	,@Search NVARCHAR(200) = NULL
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	SELECT
		S.StockTransferId
		,S.StockTransferNo
	FROM dbo.StockTransfer AS S WITH (NOLOCK)
	WHERE S.TenantId = @TenantId
		AND S.StockTransferStatus = 1 --In-Transit
		AND S.IsDeleted = 0
		AND (
			@Search IS NULL
			OR LTRIM(RTRIM(@Search)) = ''
			OR S.StockTransferNo LIKE '%' + @Search + '%'
		)
	ORDER BY S.StockTransferNo;
	END TRY
	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg
	END CATCH
END

GO

