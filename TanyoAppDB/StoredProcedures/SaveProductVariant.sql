/*
DECLARE @Pv AS dbo.[tt_productvariant]

INSERT INTO @Pv
(
 [ProductId]
)
SELECT 1
UNION ALL SELECT 2

EXEC [dbo].[SaveProductVariant]
@tv_productvariant = @Pv
,@CreatedBy = 1
*/
CREATE PROCEDURE [dbo].[SaveProductVariant] (
	@tv_productvariant [dbo].[tt_productvariant] ReadOnly
	,@CreatedBy INT = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		DECLARE @ProductVariantId BIGINT = NULL
		DECLARE @CreatedDate DATETIMEOFFSET = GETDATE()
		DECLARE @CreatedUTCDate DATETIME = GETUTCDATE()
		DECLARE @Tmp_ProductVariantIds AS TABLE (
			id INT IDENTITY(1, 1)
			,ProductVariantId BIGINT
			)

		INSERT INTO @Tmp_ProductVariantIds (ProductVariantId)
		SELECT ProductVariantId
		FROM ProductVariants pv WITH (NOLOCK)
		WHERE EXISTS (
				SELECT 1
				FROM @tv_productvariant tvpv
				WHERE tvpv.ProductId = pv.ProductId
				)

		--SELECT COUNT(1) FROM @Tmp_ProductVariantIds
		IF (
				(
					SELECT COUNT(1)
					FROM @Tmp_ProductVariantIds
					) > 0
				)
		BEGIN
			DECLARE @Tmp_ProductVariantProductIds AS TABLE (
				id INT IDENTITY(1, 1)
				,ProductId BIGINT
				)

			INSERT INTO @Tmp_ProductVariantProductIds (ProductId)
			SELECT ProductId
			FROM ProductVariants pv WITH (NOLOCK)
			WHERE EXISTS (
					SELECT 1
					FROM @Tmp_ProductVariantIds tpv
					WHERE tpv.ProductVariantId = pv.ProductVariantId
					)

			--SELECT * FROM @Tmp_ProductVariantIds
			--DELETE pv
			--SELECT pv.*
			--FROM ProductVariants pv 
			--WHERE EXISTS (SELECT 1 
			--    FROM @Tmp_ProductVariantIds tpv 
			--    WHERE tpv.ProductVariantId = pv.ProductVariantId
			--   )
			DELETE pv
			FROM ProductVariants pv
			WHERE EXISTS (
					SELECT 1
					FROM @Tmp_ProductVariantIds tpv
					WHERE tpv.ProductVariantId = pv.ProductVariantId
					)

			SELECT @ProductVariantId = MIN(ProductVariantId)
			FROM @Tmp_ProductVariantIds

			INSERT INTO dbo.ProductVariants (
				ProductId
				,ProductVariantId
				,CreatedDate
				,CreatedUTCDate
				,CreatedBy
				)
			SELECT ProductId
				,@ProductVariantId
				,@CreatedDate
				,@CreatedUTCDate
				,@CreatedBy
			FROM @tv_productvariant

			UPDATE p
			SET ProductVariantId = NULL
			FROM Products p
			WHERE EXISTS (
					SELECT 1
					FROM @Tmp_ProductVariantProductIds tvp
					WHERE tvp.ProductId = p.ProductId
					)

			UPDATE p
			SET ProductVariantId = @ProductVariantId
			FROM Products p
			WHERE EXISTS (
					SELECT 1
					FROM @tv_productvariant tvp
					WHERE tvp.ProductId = p.ProductId
					)
		END
		ELSE
		BEGIN
			SELECT TOP 1 @ProductVariantId = ISNULL(MAX(ProductVariantId), 0) + 1
			FROM ProductVariants

			INSERT INTO dbo.ProductVariants (
				ProductId
				,ProductVariantId
				,CreatedDate
				,CreatedUTCDate
				,CreatedBy
				)
			SELECT ProductId
				,@ProductVariantId
				,@CreatedDate
				,@CreatedUTCDate
				,@CreatedBy
			FROM @tv_productvariant

			UPDATE p
			SET ProductVariantId = @ProductVariantId
			FROM Products p
			WHERE EXISTS (
					SELECT 1
					FROM @tv_productvariant tvp
					WHERE tvp.ProductId = p.ProductId
					)
		END
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

