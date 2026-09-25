-- =============================================
-- Author      : MagnusMinds
-- Create date : 06-07-2026
-- Description : App API - Stock on Hold item-level list
-- Modified    : 08-07-2026 - Added HighValue support (returns rows with max UnitSalePrice)
-- =============================================
/*
EXEC App_List_GetStockOnHoldData
    @TenantId = 2,
    @UserId = 4279 ,
    @RoleId = '555D131D-3306-40AC-9A7B-6CBDA78A1C2F',
    @SalesmanName = NULL,
    @HoldStatus = 'All',
    @ProductName = NULL,
    @CustomerName = NULL,
    @ReleaseFromDate = NULL,
    @ReleaseToDate = NULL,
    @OrderNo = NULL,
    @PageIndex = 1,
    @PageSize = 25,
    @SortBy = 'releaseDate',
    @SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[App_List_GetStockOnHoldData]
(
    @TenantId INT,
    @UserId BIGINT,
    @RoleId NVARCHAR(450) = NULL,
    @SalesmanName VARCHAR(100) = NULL,
    @HoldStatus VARCHAR(50) = 'All',
    @ProductName VARCHAR(100) = NULL,
    @CustomerName VARCHAR(100) = NULL,
    @ReleaseFromDate DATE = NULL,
    @ReleaseToDate DATE = NULL,
    @OrderNo VARCHAR(20) = NULL,
    @PageIndex INT = 1,
    @PageSize INT = 25,
    @SortBy VARCHAR(50) = 'releaseDate',
    @SortOrder VARCHAR(4) = 'ASC'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    DECLARE @IsAdministrator BIT = 0;

    IF @RoleId IS NOT NULL
        AND EXISTS
        (
            SELECT 1
            FROM AspNetRoles
            WHERE Id = @RoleId
                AND Name LIKE 'Administrator%'
        )
    BEGIN
        SET @IsAdministrator = 1;
    END;

    ;WITH BaseData AS
    (
        SELECT
            soh.OrderId,
            o.OrderNo,
            CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
            CONCAT(s.FirstName, ' ', s.LastName) AS SalesmanName,
             --ROUND
               --(
             --    CASE
             --        WHEN o.GSTType = 1
             --            THEN ISNULL(osi.AmountBeforeGST, 0)
             --        ELSE osi.TotalAmount
             --    END,
             --    0
             --) AS TotalAmount,
            o.SalesmanId AS SalesmanId,
            soh.CreatedBy AS CreatedByUserId,
            CONCAT(u.FirstName, ' ', u.LastName) AS CreatedByUserName,
            ROUND(ISNULL(osi.UnitSalePrice, 0), 0) AS TotalAmount,
            MAX(ROUND(ISNULL(osi.UnitSalePrice, 0), 0)) OVER() AS MaxTotalAmount,

            c.PhoneNumber AS CustomerMobile,

            soh.ProductId,
            p.ProductTitle AS ProductName,
            p.ModelNo AS ProductModalNumber,
            osi.ProductImage AS ProductImageUrl,

            RD.ReleaseDate,

            DATEDIFF
            (
                DAY,
                CAST(GETDATE() AS DATE),
                RD.ReleaseDate
            ) + 1 AS RemainingDays,

            CASE
                WHEN soh.IsStockOnHold = 1
                    THEN 'ACTIVE'
                ELSE 'INACTIVE'
            END AS StatusType,

            CASE
                WHEN RD.ReleaseDate < CAST(GETDATE() AS DATE)
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END AS IsOverdue,

            soh.StockOnHoldId,
            soh.OrderSetItemId,
            soh.Quantity AS HoldQuantity

        FROM StockOnHold soh

        INNER JOIN Orders o
            ON soh.OrderId = o.OrderId
        INNER JOIN OrderSetItems osi
            ON soh.OrderSetItemId = osi.OrderSetItemId
        INNER JOIN Customers c
            ON o.CustomerId = c.CustomerId
        INNER JOIN AspNetUsers u
            ON soh.CreatedBy = u.UserId
        INNER JOIN Products p
            ON soh.ProductId = p.ProductId
        INNER JOIN AspNetUsers s
            ON o.SalesmanId = s.UserId
        CROSS APPLY
        (
            SELECT CAST
            (
                DATEADD
                (
                    DAY,
                    TRY_CAST(soh.TimePeriod AS INT),
                    soh.CreatedDate
                ) AS DATE
            ) AS ReleaseDate
        ) RD
        WHERE
            soh.IsStockOnHold = 1
            AND o.TenantId = @TenantId
            AND o.IsArchive = 0
            AND o.Status IN (0, 1)
            AND osi.IsQuantityOnHold = 1
            AND osi.IsDeleted = 0
            AND c.IsDeleted = 0
            --AND
            --(
            --    @IsAdministrator = 1
            --    OR soh.CreatedBy = @UserId
            --)
            AND
            (
                @HoldStatus <> 'MyHolds'
                OR soh.CreatedBy = @UserId
            )
            AND
            (
                ISNULL(@SalesmanName, '') = ''
                OR CONCAT(s.FirstName, s.LastName) LIKE '%' + REPLACE(@SalesmanName, ' ', '') + '%'
                OR s.FirstName LIKE '%' + @SalesmanName + '%'
                OR s.LastName LIKE '%' + @SalesmanName + '%'
            )
            AND
            (
                ISNULL(@ProductName, '') = ''
                OR p.ProductTitle LIKE '%' + @ProductName + '%'
                OR p.ModelNo LIKE '%' + @ProductName + '%'
            )
            AND
            (
                ISNULL(@CustomerName, '') = ''
                OR CONCAT(c.FirstName, ' ', c.LastName) LIKE '%' + @CustomerName + '%'
            )
            AND(@OrderNo IS NULL OR o.OrderNo like '%' + @OrderNo + '%')
            AND
            (
                @ReleaseFromDate IS NULL
                OR RD.ReleaseDate >= @ReleaseFromDate
            )
            AND
            (
                @ReleaseToDate IS NULL
                OR RD.ReleaseDate <= @ReleaseToDate
            )
            AND
            (
                @HoldStatus IS NULL
                OR @HoldStatus = ''
                OR @HoldStatus = 'All'
                OR @HoldStatus = 'HighValue'
                OR
                (
                    @HoldStatus = 'ExpiringToday'
                    AND RD.ReleaseDate = CAST(GETDATE() AS DATE)
                )
                --OR
                --(
                --    @HoldStatus = 'Overdue'
                --    AND RD.ReleaseDate < CAST(GETDATE() AS DATE)
                --)
                OR @HoldStatus = 'MyHolds'
            )
    )

    SELECT
        bd.OrderId,
        bd.OrderNo,
        bd.CustomerName,
        bd.SalesmanName,
        bd.SalesmanId,
        bd.CreatedByUserId,
        bd.CreatedByUserName,
        bd.TotalAmount,
        bd.CustomerMobile,
        bd.ProductId,
        bd.ProductName,
        bd.ProductModalNumber,
        bd.ProductImageUrl,
        bd.ReleaseDate,
        bd.RemainingDays,
        bd.StatusType,
        bd.IsOverdue,
        bd.StockOnHoldId,
        bd.OrderSetItemId,
        bd.HoldQuantity,
        COUNT(1) OVER() AS TotalCount
    FROM BaseData bd
    WHERE
        @HoldStatus <> 'HighValue'
        OR bd.TotalAmount = bd.MaxTotalAmount
    ORDER BY
        CASE 
            WHEN @SortBy = 'releaseDate'
                 AND @SortOrder = 'ASC'
            THEN bd.ReleaseDate
        END ASC,

        CASE
            WHEN @SortBy = 'releaseDate'
                 AND @SortOrder = 'DESC'
            THEN bd.ReleaseDate
        END DESC,

        CASE
            WHEN @SortBy = 'orderNo'
                 AND @SortOrder = 'ASC'
            THEN bd.OrderNo
        END ASC,

        CASE
            WHEN @SortBy = 'orderNo'
                 AND @SortOrder = 'DESC'
            THEN bd.OrderNo
        END DESC,

        CASE
            WHEN @SortBy = 'customerName'
                 AND @SortOrder = 'ASC'
            THEN bd.CustomerName
        END ASC,

        CASE
            WHEN @SortBy = 'customerName'
                 AND @SortOrder = 'DESC'
            THEN bd.CustomerName
        END DESC,

        CASE
            WHEN @SortBy = 'salesmanName'
                 AND @SortOrder = 'ASC'
            THEN bd.SalesmanName
        END ASC,

        CASE
            WHEN @SortBy = 'salesmanName'
                 AND @SortOrder = 'DESC'
            THEN bd.SalesmanName
        END DESC,
	    --CASE
	    --    WHEN @SortBy = 'totalAmount'
	    --         AND @SortOrder = 'ASC'
	    --    THEN ROUND
	    --            (
	    --                CASE
	    --                    WHEN o.GSTType = 1
	    --                        THEN ISNULL(osi.AmountBeforeGST, 0)
	    --                    ELSE osi.TotalAmount
	    --                END,
	    --                0
	    --            )
	    --END ASC,
	    --CASE
	    --    WHEN @SortBy = 'totalAmount'
	    --         AND @SortOrder = 'DESC'
	    --    THEN ROUND
	    --            (
	    --                CASE
	    --                    WHEN o.GSTType = 1
	    --                        THEN ISNULL(osi.AmountBeforeGST, 0)
	    --                    ELSE osi.TotalAmount
	    --                END,
	    --                0
	    --            )
	    --END DESC,
        CASE WHEN @SortBy = 'totalAmount' AND @SortOrder = 'ASC' THEN bd.TotalAmount END ASC,
        CASE WHEN @SortBy = 'totalAmount' AND @SortOrder = 'DESC' THEN bd.TotalAmount END DESC,

        CASE
            WHEN @SortBy = 'productName'
                 AND @SortOrder = 'ASC'
            THEN bd.ProductName
        END ASC,

        CASE
            WHEN @SortBy = 'productName'
                 AND @SortOrder = 'DESC'
            THEN bd.ProductName
        END DESC,

        CASE
            WHEN @SortBy = 'remainingDays'
                 AND @SortOrder = 'ASC'
            THEN bd.RemainingDays
        END ASC,

        CASE
            WHEN @SortBy = 'remainingDays'
                 AND @SortOrder = 'DESC'
            THEN bd.RemainingDays
        END DESC,

        bd.ReleaseDate ASC,
        bd.StockOnHoldId DESC

    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
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

