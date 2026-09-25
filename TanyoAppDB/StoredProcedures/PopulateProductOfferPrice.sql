-- ============================================= 
-- Author : MagnusMinds
-- Create date : 02-07-2025
-- Description : Assign the offer price as per the offer running
-- ============================================= 
/* EXEC [dbo].[PopulateProductOfferPrice] @OfferId = NULL ,@OldOfferPercentage = NULL */
CREATE PROCEDURE [dbo].[PopulateProductOfferPrice] (
	@OfferId BIGINT = NULL
	,@OldOfferPercentage INT = NULL
	,@UserID INT = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		--SET NOCOUNT ON; 
		DECLARE @Date DATE = GETDATE();
		DECLARE @TenantId INT
			,@ProductSubjectTypeId INT
			,@dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@dtUTC DATETIME = GETUTCDATE()

		IF ISNULL(@OfferId, 0) > 0
		BEGIN
			SELECT @TenantId = TenantId
			FROM Offers WITH (NOLOCK)
			WHERE OfferId = @OfferId

			SELECT @ProductSubjectTypeId = SubjectTypeId
			FROM SubjectTypes WITH (NOLOCK)
			WHERE tenantid = @TenantId
				AND SubjectTypeName = 'Products'

			UPDATE p
			SET p.RetailOfferPrice = NULL
				,p.WholesalerOfferPrice = NULL
			FROM Products p
			INNER JOIN OfferProductMapping opm1 ON opm1.ProductId = p.ProductId
			WHERE (
					p.RetailOfferPrice IS NOT NULL
					OR p.WholesalerOfferPrice IS NOT NULL
					)
				AND NOT EXISTS (
					SELECT 1
					FROM OfferProductMapping opm
					WHERE opm.ProductId = p.ProductId
						AND opm.OfferId = @OfferId
					)
				AND opm1.OfferId = @OfferId

			DECLARE @Inc INT = 1;
			DECLARE @Cnt INT;
			DECLARE @SubjectId BIGINT;
			DECLARE @Description VARCHAR(MAX);

			CREATE TABLE #ActivityLogData (
				RowId INT IDENTITY(1, 1)
				,SubjectId BIGINT
				,Description VARCHAR(MAX)
				);

			INSERT INTO #ActivityLogData (
				SubjectId
				,Description
				)
			SELECT P.ProductId
				,'Offer Percentage changed from ' + CAST(ISNULL(@OldOfferPercentage, 0) AS VARCHAR(100)) + '% to ' + CAST(O.OfferPercentage AS VARCHAR(100)) + '%. Retailer offer price updated from ' + CAST(ISNULL(p.RetailOfferPrice, 0) AS VARCHAR(100)) + ' to ' + CAST(CAST(ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2) AS NUMERIC(18, 2)) AS VARCHAR(100))
			FROM Products p
			INNER JOIN OfferProductMapping opm ON opm.ProductId = p.ProductId
			INNER JOIN Offers o ON o.OfferId = opm.OfferId
			WHERE o.StartDate <= @Date
				AND o.OfferId = @OfferId
				AND o.EndDate >= @Date
				AND o.IsPublished = 1
				AND (
					ISNULL(p.RetailOfferPrice, 0) <> ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2)
					OR ISNULL(p.WholesalerOfferPrice, 0) <> ROUND((p.WholesalerPrice - ((p.WholesalerPrice * o.OfferPercentage) / 100)), 2)
					);

			SELECT @Cnt = COUNT(1) FROM #ActivityLogData;

			WHILE @Cnt >= @Inc
			BEGIN
				SELECT @SubjectId = SubjectId
					,@Description = Description
				FROM #ActivityLogData
				WHERE RowId = @Inc;

				EXEC dbo.SaveActivityLog @SubjectTypeId = @ProductSubjectTypeId
					,@SubjectId = @SubjectId
					,@Description = @Description
					,@Action = 'UPDATE'
					,@CreatedBy = @UserID
					,@CreatedDate = @dt
					,@CreatedUTCDate = @dtUTC;

				SET @Inc = @Inc + 1;
			END;

			DROP TABLE #ActivityLogData;
		END

		UPDATE p
		SET p.RetailOfferPrice = ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2)
			,p.WholesalerOfferPrice = ROUND((p.WholesalerPrice - ((p.WholesalerPrice * o.OfferPercentage) / 100)), 2)
		FROM Products p
		INNER JOIN OfferProductMapping opm ON opm.ProductId = p.ProductId
		INNER JOIN Offers o ON o.OfferId = opm.OfferId
		WHERE o.StartDate <= @Date
			AND o.EndDate >= @Date
			AND (
				@OfferId IS NULL
				OR o.OfferId = @OfferId
				)
			AND o.IsPublished = 1
			AND (
				ISNULL(p.RetailOfferPrice, 0) <> ROUND((p.RetailerPrice - ((p.RetailerPrice * o.OfferPercentage) / 100)), 2)
				OR ISNULL(p.WholesalerOfferPrice, 0) <> ROUND((p.WholesalerPrice - ((p.WholesalerPrice * o.OfferPercentage) / 100)), 2)
				)
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)
		SET @ErrorMsg = ERROR_MESSAGE()

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg
	END CATCH
END

GO

