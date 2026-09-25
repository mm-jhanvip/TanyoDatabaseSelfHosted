-- =============================================
-- Author:  MagnusMinds
-- Create date: 22-Jul-2025
-- Description: Get count of Inward
-- =============================================
/*
EXEC Dashboard_GetInwardCount
 @TenantId = 2
*/ 
CREATE   PROCEDURE [dbo].[Dashboard_GetInwardCount]
    @TenantId INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT COUNT(*) AS StatusCount
    FROM InwardEntry i
    INNER JOIN AspNetUsers AU ON AU.UserId = I.CreatedBy  -- To maintain consistency for tile and InwardList
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

