/*
	EXEC [dbo].[DeleteProductOfferAndMapping] @TenantId = NULL, @ProductIds = ''
*/
CREATE     PROCEDURE [dbo].[DeleteProductOfferAndMapping] (
	@TenantId INT = NULL
	,@ProductIds VARCHAR(MAX) = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Dt DATETIME = GETDATE()

	DECLARE @Tmp_ProductIds AS TABLE
	(
		Id INT IDENTITY(1,1)
		,ProductId BIGINT PRIMARY KEY
	)

	BEGIN TRY

	INSERT INTO @Tmp_ProductIds
	(
		ProductId
	)
	SELECT value 
	FROM string_split(@ProductIds,',')

	BEGIN TRANSACTION DeleteProductMapping
	
	DELETE FROM ProductOffers WHERE TenantId = @TenantId AND ProductId IN (SELECT ProductId FROM @Tmp_ProductIds)
	DELETE FROM OfferProductMapping WHERE ProductId IN (SELECT ProductId FROM @Tmp_ProductIds)
	UPDATE Products
	SET RetailOfferPrice = NULL
	WHERE TenantId = @TenantId
	  AND ProductId IN (SELECT ProductId FROM @Tmp_ProductIds)

	COMMIT TRANSACTION DeleteProductMapping
		
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

