-- =============================================
-- Author:  MagnusMinds
-- Create date: 22-Jul-2025
-- Description: Get count of Orders which are in Inquiry status
-- =============================================
/*
--Admin
EXEC Dashboard_GetOrderInquiryCount
 @TenantId = 2,
 @CurrentUserId = 4328,
 @RoleId = '555D131D-3306-40AC-9A7B-6CBDA78A1C2F'

--SalesRepresentative
EXEC Dashboard_GetOrderInquiryCount
 @TenantId = 2,
 @CurrentUserId = 4386,
 @RoleId = '17BE52F0-731D-4215-9CA3-021C068A9F6F'
*/
CREATE PROCEDURE [dbo].[Dashboard_GetOrderInquiryCount]
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
        @IsWholesaler BIT = 0,
        @OrderStatus INT = 0;

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

    -- OrderTypeEnum: Retailer = 1, Wholesaler = 2
    DECLARE @ExpectedOrderType INT = CASE WHEN @IsWholesaler = 1 THEN 2 ELSE 1 END;

    SELECT COUNT(1) AS StatusCount
    FROM Orders o WITH (NOLOCK)
    WHERE o.TenantId = @TenantId
      AND o.Status = @OrderStatus
      AND o.IsArchive = 0
      AND (
            @IsAdmin = 1
            OR (@IsAdmin = 0 AND @HasSuperAccess = 1 AND o.OrderType = @ExpectedOrderType)
            OR (@IsAdmin = 0 AND @HasSuperAccess = 0 
                AND o.SalesmanId = @CurrentUserId 
                AND o.OrderType = @ExpectedOrderType)
        )
END

GO

