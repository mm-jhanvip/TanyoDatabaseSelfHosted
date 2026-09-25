/*
	EXEC [dbo].[PopulateProductOffers] @TenantId = NULL, @OfferId = @OfferId, @ProductIds = NULL
*/
CREATE PROCEDURE [dbo].[PopulateProductOffers] (
	@TenantId INT = NULL
	,@OfferId INT = NULL
	,@ProductIds VARCHAR(MAX) = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Dt DATE = GETDATE()
	DECLARE @Tmp_ProductIds AS TABLE (
		Id INT IDENTITY(1, 1)
		,ProductId BIGINT PRIMARY KEY
		)

	BEGIN TRY
		INSERT INTO @Tmp_ProductIds (ProductId)
		SELECT value
		FROM string_split(@ProductIds, ',')

		BEGIN TRANSACTION Productoffers

		IF (@TenantId IS NULL)
		BEGIN
			TRUNCATE TABLE Productoffers
		END
		ELSE IF (@OfferId IS NULL)
		BEGIN
			DELETE
			FROM ProductOffers
			WHERE TenantId = @TenantId
		END
		ELSE IF (NULLIF(@ProductIds, '') IS NULL)
		BEGIN
			DELETE
			FROM ProductOffers
			WHERE TenantId = @TenantId
				AND OfferId = @OfferId
		END
		ELSE
		BEGIN
			DELETE
			FROM ProductOffers
			WHERE TenantId = @TenantId
				AND ProductId IN (
					SELECT ProductId
					FROM @Tmp_ProductIds
					)
		END

		INSERT INTO ProductOffers (
			ProductId
			,TenantId
			,OfferId
			,StartDate
			,EndDate
			,OfferPercentage
			,OfferCode
			,CreatedDate
			)
		SELECT opm.ProductId
			,t.TenantId
			,opm.OfferId
			,ofr.StartDate
			,ofr.EndDate
			,ofr.OfferPercentage
			,ofr.OfferCode
			,@Dt
		FROM dbo.OfferProductMapping AS opm WITH (NOLOCK)
		INNER JOIN dbo.Products AS p WITH (NOLOCK) ON p.ProductId = opm.ProductId
			AND p.Status <> 3
		INNER JOIN dbo.Offers AS ofr WITH (NOLOCK) ON opm.offerId = ofr.OfferId
		INNER JOIN Tenants AS t WITH (NOLOCK) ON ofr.TenantId = t.TenantId
		WHERE ofr.IsDeleted = 0
			AND ofr.IsPublished = 1 --Only Active
			AND ofr.StartDate <= @dt
			AND ofr.EndDate >= @dt
			AND (
				t.TenantId = @TenantId
				OR @TenantId IS NULL
				)
			AND (
				@OfferId IS NULL
				OR ofr.OfferId = @OfferId
				)
			AND (
				@ProductIds IS NULL
				OR opm.ProductId IN (
					SELECT ProductId
					FROM @Tmp_ProductIds
					)
				)
		GROUP BY opm.ProductId
			,t.TenantId
			,opm.OfferId
			,ofr.StartDate
			,ofr.EndDate
			,ofr.OfferPercentage
			,ofr.OfferCode;

		COMMIT TRANSACTION Productoffers
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX)

		SET @ObjectName = OBJECT_NAME(@@PROCID)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		EXEC dbo.SaveDBErrorLog 
			 @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage
	END CATCH
END

GO

