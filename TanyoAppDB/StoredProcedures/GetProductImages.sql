-- =============================================  
-- Author      : MagnusMinds  
-- Create date : 15-09-2026  
-- Description : Retrieves published product images for a specific tenant
-- =============================================  
/*  
EXEC [dbo].[GetProductImages]  
    @TenantId = 1207  
*/

CREATE PROCEDURE [dbo].[GetProductImages]
(
    @TenantId INT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH ProductImageData AS
        (
            SELECT
                p.ProductId,
                pi.ProductImageID AS ProductImageId,
                pi.IsCover AS IsCoverImage,
                CASE 
                    WHEN CHARINDEX('?', pi.ImagePath) > 0
                        THEN LEFT(pi.ImagePath, CHARINDEX('?', pi.ImagePath) - 1)
                    ELSE pi.ImagePath
                END AS ImagePath
            FROM dbo.Products p WITH (NOLOCK)
            INNER JOIN dbo.ProductImages pi WITH (NOLOCK)
                ON p.ProductId = pi.ProductId
            WHERE p.TenantId = @TenantId
              AND p.Status = 1
        )
        SELECT
            ProductId,
            ProductImageId,
            CASE
                WHEN ImagePath IS NULL OR ImagePath = '' THEN ''
                WHEN CHARINDEX('/', ImagePath) = 0 THEN ImagePath
                ELSE RIGHT(ImagePath, CHARINDEX('/', REVERSE(ImagePath)) - 1)
            END AS ImageName,
            IsCoverImage
        FROM ProductImageData
        ORDER BY ProductId, ProductImageId;
    END TRY
    BEGIN CATCH

    DECLARE 
        @ObjectName VARCHAR(500),
        @ErrorMsg VARCHAR(MAX);

    SET @ObjectName = OBJECT_NAME(@@PROCID);
    SET @ErrorMsg = ERROR_MESSAGE();

    EXEC dbo.SaveDBErrorLog
        @ObjectName = @ObjectName,
        @ErrorMsg = @ErrorMsg;
END CATCH
END

GO

