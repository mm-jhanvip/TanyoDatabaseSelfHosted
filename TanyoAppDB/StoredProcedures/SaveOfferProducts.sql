/*
EXEC [dbo].[SaveOfferProducts]
	@OfferId = 3337,                           
	@ProductIds = '402783,402784,402785',       
	@TenantId = 2,                            
	@UserId = 4279,                           
	@IsApplyFromOffer = 1;  
*/
CREATE PROCEDURE [dbo].[SaveOfferProducts] (
	@OfferId BIGINT
	,@ProductIds NVARCHAR(MAX)
	,@TenantId BIGINT
	,@UserId BIGINT
	,@IsApplyFromOffer BIT = 0
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #IncomingProducts;

		DECLARE @DateNow DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DateUtcNow DATETIME = GETUTCDATE()
			,@ReturnMessage VARCHAR(512)

	-- 1. Create table with RowID for looping activity logs
	CREATE TABLE #IncomingProducts (
		RowID INT IDENTITY(1, 1)
		,ProductId BIGINT
		);

	INSERT INTO #IncomingProducts (ProductId)
	SELECT CAST(value AS BIGINT)
	FROM STRING_SPLIT(@ProductIds, ',')
	WHERE LTRIM(RTRIM(value)) <> '';

	BEGIN TRY
		BEGIN TRAN SaveOfferProducts;

		-- 3. Delete existing mapping
		IF (@IsApplyFromOffer = 1)
		BEGIN
			DELETE
			FROM dbo.OfferProductMapping
			WHERE OfferId = @OfferId;

			DELETE OPM
			FROM dbo.OfferProductMapping OPM
			INNER JOIN #IncomingProducts ip ON ip.ProductId = OPM.ProductId;
		END
		ELSE
		BEGIN
			DELETE OPM
			FROM dbo.OfferProductMapping OPM
			INNER JOIN #IncomingProducts ip ON ip.ProductId = OPM.ProductId;
		END

		-- 4. Insert new mapping
		INSERT INTO dbo.OfferProductMapping (
			ProductId
			,OfferId
			,LastModifiedBy
			,LastModifiedDate
			,LastModifiedUTCDate
			)
		SELECT ip.ProductId
			,@OfferId
			,@UserId
			,@DateNow
			,@DateUtcNow
		FROM #IncomingProducts ip
		WHERE NOT EXISTS (
				SELECT 1
				FROM dbo.OfferProductMapping opm
				WHERE opm.ProductId = ip.ProductId
				);

		COMMIT TRAN SaveOfferProducts;

		DROP TABLE IF EXISTS #IncomingProducts;

			SELECT 1 AS [Status]
				,'Products have been mapped successfully.' AS [Message];
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SaveOfferProducts;

		DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
		DECLARE @ErrorState INT = ERROR_STATE()
		DECLARE @ObjectName VARCHAR(500)

		SET @ObjectName = OBJECT_NAME(@@PROCID);

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT 0 AS [Status]
			,'An error occurred: ' + @ErrorMsg AS [Message];
	END CATCH
END

GO

