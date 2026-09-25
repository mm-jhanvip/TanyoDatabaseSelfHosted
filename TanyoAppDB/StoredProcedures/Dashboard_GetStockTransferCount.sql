-- =============================================
-- Author:  MagnusMinds
-- Create date: 27-Jul-2026
-- Description: Get count of Inward
-- =============================================
/*
EXEC Dashboard_GetStockTransferCount
 @TenantId = 2
*/ 
CREATE   PROCEDURE [dbo].[Dashboard_GetStockTransferCount]
    @TenantId INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT COUNT(*) AS StatusCount
    FROM StockTransfer i
    WHERE i.TenantId = @TenantId
      AND i.IsDeleted = 0
     END TRY
     BEGIN CATCH
        DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
		
		
     END CATCH
END

GO

