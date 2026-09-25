
-- =============================================
-- Author:  MagnusMinds
-- Create date: 22-Jul-2025
-- Description: Get count of Orders which are in Receivable status
-- =============================================
/*
--Admin
EXEC Dashboard_GetReceivableOrderCount
 @TenantId = 2,
 @CurrentUserId = 4328,
 @RoleId = '555D131D-3306-40AC-9A7B-6CBDA78A1C2F'

--SalesRepresentative
EXEC Dashboard_GetReceivableOrderCount
 @TenantId = 2,
 @CurrentUserId = 4386,
 @RoleId = '17BE52F0-731D-4215-9CA3-021C068A9F6F'
*/
CREATE   PROCEDURE [dbo].[Dashboard_GetReceivableOrderCount]
    @TenantId INT,
    @CurrentUserId INT,
    @RoleId NVARCHAR(100)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @IsAdmin BIT = 0,
        @HasSuperAccess BIT = 0,
        @IsWholesaler BIT = 0;

    IF EXISTS (
        SELECT 1 FROM AspNetRoleClaims
        WHERE RoleId = @RoleId AND ClaimValue = 'Permissions.App.Order.Approve'
    )
        SET @IsAdmin = 1;

    IF EXISTS (
        SELECT 1 FROM AspNetRoleClaims
        WHERE RoleId = @RoleId AND ClaimValue = 'Permissions.App.Order.SuperAccess'
    )
        SET @HasSuperAccess = 1;

    IF EXISTS (
        SELECT 1 FROM AspNetRoleClaims
        WHERE RoleId = @RoleId AND ClaimValue = 'Permissions.App.Order.WholeselerPrice'
    )
        SET @IsWholesaler = 1;

    DECLARE @ExpectedOrderType INT = CASE WHEN @IsWholesaler = 1 THEN 2 ELSE 1 END;

    ;WITH OrderBase AS (
        SELECT o.OrderId
        FROM Orders o
        WHERE o.TenantId = @TenantId
          AND o.IsArchive = 0
          AND o.Status = 2 -- Approved
          AND (
                @IsAdmin = 1 OR
                (
                    @HasSuperAccess = 1 AND o.OrderType = @ExpectedOrderType
                ) OR
                (
                    o.CreatedBy = @CurrentUserId AND o.OrderType = @ExpectedOrderType
                )
              )
    ),
    ReceivableOrders AS (
        SELECT DISTINCT o.OrderId
        FROM OrderBase o
        INNER JOIN OrderSetItems osi ON o.OrderId = osi.OrderId
			AND osi.ReceiveDate IS NOT NULL
			AND osi.IsDeleted = 0
        LEFT JOIN OrderSetItemReceivables osir ON osi.OrderSetItemId = osir.OrderSetItemId
        WHERE osir.OrderSetItemId IS NULL
    )

    SELECT COUNT(*) AS StatusCount FROM ReceivableOrders;
END

GO

