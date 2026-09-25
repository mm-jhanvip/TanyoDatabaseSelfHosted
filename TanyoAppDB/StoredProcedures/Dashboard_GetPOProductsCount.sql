-- =============================================
-- Author:  MagnusMinds
-- Create date: 12-Nov-2025
-- Description: Get count of PO Products
-- =============================================
/*
    EXEC [dbo].[Dashboard_GetPOProductsCount]
        @TenantId = 2
*/ 
CREATE   PROCEDURE [dbo].[Dashboard_GetPOProductsCount]
    @TenantId INT
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(1) AS StatusCount
    FROM POProducts WITH (NOLOCK)
    WHERE TenantId = @TenantId
    AND IsDeleted = 0
    AND Status IN (1,2,5) --Pending, Approved, Material Ready
END

GO

