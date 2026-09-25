
/*
	EXEC RemoveUnmappedPO
	@TenantId        =  2,
    @POProductItemIds = '41962',
    @UserId          = 4279
*/
CREATE   PROCEDURE [dbo].[RemoveUnmappedPO]
(
    @TenantId        BIGINT,
    @POProductItemIds NVARCHAR(MAX),
    @UserId          BIGINT,
	@ReturnMessage	 NVARCHAR(255) = '' OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE 
            @Date                 DATETIMEOFFSET = SYSDATETIMEOFFSET(),
            @DateUTC              DATETIMEOFFSET = SYSUTCDATETIME(),
            @ProductSubjectTypeId INT;	

        -------------------------------------------------------
        -- 1. Create Temp Table for input POProductItemIds
        -------------------------------------------------------
        IF OBJECT_ID('tempdb..#POProductItemIds') IS NOT NULL
            DROP TABLE #POProductItemIds;

        CREATE TABLE #POProductItemIds
        (
            POProductItemId BIGINT PRIMARY KEY
        );

        INSERT INTO #POProductItemIds (POProductItemId)
        SELECT DISTINCT TRY_CAST(value AS BIGINT)
        FROM STRING_SPLIT(@POProductItemIds, ',')
        WHERE TRY_CAST(value AS BIGINT) IS NOT NULL;

        -------------------------------------------------------
        -- 2. Identify Unmapped Product details
        -------------------------------------------------------
        IF OBJECT_ID('tempdb..#UnmappedProducts') IS NOT NULL
            DROP TABLE #UnmappedProducts;

        CREATE TABLE #UnmappedProducts
        (
            RowId           INT IDENTITY(1,1) PRIMARY KEY,
            POProductItemId BIGINT,
            ProductId       BIGINT,
            POProductId     BIGINT,
            ProductName     NVARCHAR(500),
            ModelNo     NVARCHAR(100),
            VendorName      NVARCHAR(500)
        );

        INSERT INTO #UnmappedProducts (POProductItemId, ProductId, POProductId, ProductName, ModelNo, VendorName)
        SELECT
            PPI.POProductItemId,
            PPI.ProductId,
            PPI.POProductId,
            P.ProductTitle,
            P.ModelNo,
            V.VendorName
        FROM #POProductItemIds PI
        INNER JOIN POProductItems PPI WITH (NOLOCK)
            ON PI.POProductItemId = PPI.POProductItemId
        INNER JOIN POProducts POP WITH (NOLOCK)
            ON POP.POProductId = PPI.POProductId
        INNER JOIN Products P WITH (NOLOCK)
            ON P.ProductId = PPI.ProductId
        INNER JOIN Vendors V WITH (NOLOCK)
            ON V.VendorId = POP.VendorId
        LEFT JOIN ProductVendorMapping PVM WITH (NOLOCK)
            ON PPI.ProductId = PVM.ProductId
           AND PVM.VendorId  = POP.VendorId
           AND PVM.IsDeleted = 0
        WHERE POP.TenantId  = @TenantId
          AND POP.IsDeleted = 0
          AND PVM.ProductId IS NULL;

        -------------------------------------------------------
        -- 3. Check: If no unmapped products found
        -------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM #UnmappedProducts)
        BEGIN
            SET @ReturnMessage = 'Product has already been removed.';
            RETURN;
        END;

        -------------------------------------------------------
        -- 4. Get SubjectTypeId safely
        -------------------------------------------------------
        SELECT @ProductSubjectTypeId = SubjectTypeId
        FROM SubjectTypes WITH (NOLOCK)
        WHERE TenantId        = @TenantId
          AND SubjectTypeName = 'Products';

        -------------------------------------------------------
        -- 5. Store Distinct Affected POProductIds
        -------------------------------------------------------
        IF OBJECT_ID('tempdb..#AffectedPOIds') IS NOT NULL
            DROP TABLE #AffectedPOIds;

        CREATE TABLE #AffectedPOIds
        (
            POProductId BIGINT PRIMARY KEY
        );

        INSERT INTO #AffectedPOIds (POProductId)
        SELECT DISTINCT POProductId
        FROM #UnmappedProducts;

        -------------------------------------------------------
        -- 6. Perform Deletion, Update, and Activity Logging
        -------------------------------------------------------
        BEGIN TRANSACTION;

            DELETE PI
            FROM POProductItems PI
            INNER JOIN #UnmappedProducts U
                ON PI.POProductItemId = U.POProductItemId;

            UPDATE POP
            SET
                TotalAmount     = ISNULL(T.TotalAmount, 0),
                AmountBeforeGST = ISNULL(T.AmountBeforeGST, 0),
                CGSTAmount      = ISNULL(T.CGSTAmount, 0),
                SGSTAmount      = ISNULL(T.SGSTAmount, 0),
                IGSTAmount      = ISNULL(T.IGSTAmount, 0),
                UpdatedBy       = @UserId,
                UpdatedDate     = @Date,
                UpdatedUTCDate  = @DateUTC
            FROM POProducts POP
            INNER JOIN #AffectedPOIds AP
                ON AP.POProductId = POP.POProductId
            LEFT JOIN
            (
                SELECT
                    PPI.POProductId,
                    SUM(ISNULL(PPI.TotalAmount, 0))     AS TotalAmount,
                    SUM(ISNULL(PPI.AmountBeforeGST, 0)) AS AmountBeforeGST,
                    SUM(ISNULL(PPI.CGSTAmount, 0))      AS CGSTAmount,
                    SUM(ISNULL(PPI.SGSTAmount, 0))      AS SGSTAmount,
                    SUM(ISNULL(PPI.IGSTAmount, 0))      AS IGSTAmount
                FROM POProductItems PPI WITH (NOLOCK)
                INNER JOIN #AffectedPOIds AP
                    ON AP.POProductId = PPI.POProductId
                GROUP BY PPI.POProductId
            ) T ON T.POProductId = POP.POProductId;

            IF @ProductSubjectTypeId IS NOT NULL
            BEGIN
                DECLARE
                    @POProductItemId   BIGINT,
                    @ProductName NVARCHAR(500),
                    @ModelNo	 NVARCHAR(100),
                    @VendorName  NVARCHAR(500),
                    @Desc        NVARCHAR(MAX),
                    @RowId       INT = 0,
                    @TotalRows   INT;

                SELECT @TotalRows = COUNT(1) FROM #UnmappedProducts;

                WHILE @RowId < @TotalRows
                BEGIN
                    SET @RowId = @RowId + 1;

                    SELECT
						@POProductItemId = POProductItemId,
                        @ProductName = ProductName,
                        @ModelNo = ModelNo,
                        @VendorName  = VendorName
                    FROM #UnmappedProducts
                    WHERE RowId = @RowId;

                    SET @Desc = 'Product ' + ISNULL(@ProductName, '')
                              + ' (' + ISNULL(@ModelNo, '') + ')'
                              + ' was removed from the Purchase Order'
                              + ' because it was not mapped to vendor '
                              + ISNULL(@VendorName, '') + '.';

                    BEGIN TRY
                        EXEC dbo.SaveActivityLog
                            @SubjectTypeId  = @ProductSubjectTypeId,
                            @SubjectId      = @POProductItemId,
                            @Description    = @Desc,
                            @Action         = 'DELETE',
                            @CreatedBy      = @UserId,
                            @CreatedDate    = @Date,
                            @CreatedUTCDate = @DateUTC;
                    END TRY
                    BEGIN CATCH
                    END CATCH;
                END;
            END;

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS STATUS, 'POProductItem removed successfully.' AS Message;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ObjectName VARCHAR(500),
            @ErrorMsg   VARCHAR(MAX);

        SET @ObjectName = OBJECT_NAME(@@PROCID);
        SET @ErrorMsg   = ERROR_MESSAGE();

        EXEC dbo.SaveDBErrorLog
            @ObjectName = @ObjectName,
            @ErrorMsg   = @ErrorMsg;

        SELECT CAST(0 AS BIT) AS STATUS, ISNULL(@ErrorMsg, 'An unexpected error occurred.') AS Message;

    END CATCH
END

GO

