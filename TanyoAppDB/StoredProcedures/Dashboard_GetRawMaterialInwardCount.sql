-- =============================================
-- Author:  MagnusMinds
-- Create date: 30-Oct-2025
-- Description: Get count of Raw Material Inward
-- =============================================
/*
    EXEC [dbo].[Dashboard_GetRawMaterialInwardCount]
        @TenantId = 2
*/ 
CREATE   PROCEDURE [dbo].[Dashboard_GetRawMaterialInwardCount]
    @TenantId INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT COUNT(*) AS StatusCount
    FROM RawMaterialInwardEntry i
    LEFT JOIN Vendors v ON i.VendorId = v.VendorId
		AND v.TenantId = @TenantId
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

