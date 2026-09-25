-- =============================================  
--Author		: Kishan kalena
--Create date	: 04/22/2024 
--Description	: CategorySalesByMonthYearChart
-- =============================================
/*
	EXEC CategorySalesByMonthYearChart
		 @TenantId = 1
		,@TargetYear = 2024

*/
CREATE PROCEDURE [dbo].[SalesCategoryAnalysisChart] (
    @TenantId INT,
    @TargetYear INT
)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @ProductSubjectTypeId INT;

    SELECT @ProductSubjectTypeId = SubjectTypeId
    FROM SubjectTypes
    WHERE SubjectTypeName = 'Products'
        AND TenantId = @TenantId
        AND IsDeleted = 0;

    BEGIN TRY
        -- Query to fetch month-wise category data
        WITH MonthlyCategoryData
        AS (
            SELECT
                c.CategoryId,
                c.CategoryName AS CategoryName,
                ROUND(SUM(osi.AmountBeforeGST + osi.CGSTAmount + osi.SGSTAmount), 0) AS TotalAmount,
                DATEPART(YEAR, COALESCE(osi.DeliveryDate, o.ApprovedDate)) AS Year,
                DATEPART(MONTH, COALESCE(osi.DeliveryDate, o.ApprovedDate)) AS Month,

                ROW_NUMBER() OVER (
                    PARTITION BY DATEPART(YEAR, COALESCE(osi.DeliveryDate, o.ApprovedDate)),
                    DATEPART(MONTH, COALESCE(osi.DeliveryDate, o.ApprovedDate)) ORDER BY ROUND(SUM(osi.AmountBeforeGST + osi.CGSTAmount + osi.SGSTAmount), 0) DESC
                ) AS Rank
            FROM OrderSetItems osi
            INNER JOIN Orders AS o ON o.OrderId = osi.OrderId
            INNER JOIN Products AS p ON p.ProductId = osi.SubjectId
            INNER JOIN Categories AS c ON c.CategoryId = p.CategoryId
            WHERE osi.IsDeleted = 0
                AND c.IsDeleted = 0
                AND o.TenantId = @TenantId
                AND o.Status = 5
                AND osi.SubjectTypeId = @ProductSubjectTypeId
                AND YEAR(COALESCE(osi.DeliveryDate, o.ApprovedDate)) = @TargetYear
            GROUP BY c.CategoryId,
                     c.CategoryName,
                     DATEPART(YEAR, COALESCE(osi.DeliveryDate, o.ApprovedDate)),
                     DATEPART(MONTH, COALESCE(osi.DeliveryDate, o.ApprovedDate))
        )
        SELECT 
            CASE 
                WHEN mcd.Rank <= 10 THEN mcd.CategoryName
                ELSE 'Other'
            END AS 'CategoryName',
            CASE 
                WHEN mcd.Rank <= 10 THEN mcd.CategoryId
                ELSE 0 -- Assigning 0 for 'Other' category
            END AS 'CategoryId',
            SUM(mcd.TotalAmount) AS 'TotalAmount',
            mcd.Year,
            mcd.Month
        FROM MonthlyCategoryData mcd
        GROUP BY 
            CASE 
                WHEN mcd.Rank <= 10 THEN mcd.CategoryName
                ELSE 'Other'
            END,
            CASE 
                WHEN mcd.Rank <= 10 THEN mcd.CategoryId
                ELSE 0
            END,
            mcd.Year,
            mcd.Month

        UNION ALL

        -- Add row for "Other" category total in each month
        SELECT 
            'Other' AS 'CategoryName',
            0 AS 'CategoryId',
            SUM(TotalAmount) AS 'TotalAmount',
            Year,
            Month
        FROM MonthlyCategoryData
        WHERE Rank > 10
        GROUP BY 
            Year,
            Month
        HAVING NOT EXISTS (
                SELECT 1
                FROM MonthlyCategoryData mcd2
                WHERE mcd2.Year = Year
                    AND mcd2.Month = Month
                    AND mcd2.Rank <= 10
            )

        ORDER BY Year ASC, Month ASC;
    END TRY

    BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
    END CATCH
END

GO

