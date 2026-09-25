/*
EXEC SaveProductSets
@ProductSetId  = 0
,@SetName = 'Set'
,@Description  = 'This is to test update'
,@SetImage VARCHAR(MAX) = 'SetImage'
,@ProductId  = '95083,95082,95080'
,@UserId  = 4492
,@TenantId =125

EXEC SaveProductSets
@ProductSetId  = 0
,@SetName = 'Set'
,@Description  = 'This is to test update'
,@SetImage VARCHAR(MAX) = 'SetImage'
,@ProductId  = '95089,95088,95085'
,@UserId  = 4515
,@TenantId =2

*/
CREATE PROCEDURE [dbo].[SaveProductSets] (
	@ProductSetId BIGINT
	,@SetName VARCHAR(510)
	,@Description VARCHAR(500)
	,@SetImage VARCHAR(MAX)
	,@ProductId VARCHAR(MAX)
	,@ProductQuantities VARCHAR(MAX) = NULL
	,@UserId INT
	,@TenantId INT
	,@DeletedImageIds VARCHAR(MAX) = NULL
	,@ProductSetImages NVARCHAR(MAX) = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @dt DATETIMEOFFSET = SYSDATETIMEOFFSET()
		,@dtUTC DATETIME = GETUTCDATE()
		,@Status INT = 0
		,@Message VARCHAR(256) = ''
		,@NewProductCount INT
		,@OldProductCount INT

	--,@NewProductSetId BIGINT
	DROP TABLE IF EXISTS #ProductList;

		WITH ProductIdList
		AS (
			SELECT TRY_CAST(LTRIM(RTRIM(value)) AS BIGINT) AS ProductId
				,ROW_NUMBER() OVER (
					ORDER BY (
							SELECT NULL
							)
					) AS RowNum
			FROM STRING_SPLIT(@ProductId, ',')
			WHERE LTRIM(RTRIM(value)) <> ''
			)
			,ProductQtyList
		AS (
			SELECT TRY_CAST(LTRIM(RTRIM(value)) AS DECIMAL(18, 4)) AS Quantity
				,ROW_NUMBER() OVER (
					ORDER BY (
							SELECT NULL
							)
					) AS RowNum
			FROM STRING_SPLIT(ISNULL(@ProductQuantities, ''), ',')
			WHERE LTRIM(RTRIM(value)) <> ''
			)
		SELECT p.ProductId
			,ISNULL(NULLIF(q.Quantity, 0), 1) AS Quantity
			,p.RowNum
		INTO #ProductList
		FROM ProductIdList p
		LEFT JOIN ProductQtyList q ON p.RowNum = q.RowNum
		WHERE p.ProductId IS NOT NULL

	SELECT @NewProductCount = COUNT(ProductId)
	FROM #ProductList

	--IF @ProductSetId = 0
	--	AND ISNULL(@ProductId, '') = ''
	--BEGIN
	--	SET @Status = 0
	--	SET @Message = 'Invalid Request'
	--	SELECT @Status AS [Status]
	--		,@Message AS [Message]
	--	RETURN;
	--END
	BEGIN TRY
		BEGIN TRAN SaveProductSets;

		IF ISNULL(@ProductSetId, 0) = 0
			AND NOT EXISTS (
				SELECT 1
				FROM ProductSets
				WHERE ProductSetId = @ProductSetId
					AND IsDeleted = 0
					AND TenantId = @TenantId
				)
		BEGIN
			INSERT INTO ProductSets (
				SetName
				,Description
				,QRImage
				,SetImage
				,TenantId
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			SELECT @SetName
				,@Description
				,''
				,@SetImage
				,@TenantId
				,@UserId
				,@dt
				,@dtUTC

			SET @ProductSetId = SCOPE_IDENTITY()

			INSERT INTO ProductSetItems (
				ProductSetId
				,ProductId
				,Quantity
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			SELECT @ProductSetId
				,ProductId
				,Quantity
				,@UserId
				,@dt
				,@dtUTC
			FROM #ProductList
			ORDER BY ProductId

			SET @Status = 1
			SET @Message = 'Product Set created successfully'
		END
		ELSE
		BEGIN
			UPDATE ProductSets
			SET SetName = @SetName
				,Description = @Description
				,SetImage = @SetImage
				,UpdatedBy = @UserId
				,UpdatedDate = @dt
				,UpdatedUTCDate = @dtUTC
			WHERE ProductSetId = @ProductSetId
				AND IsDeleted = 0
				AND TenantId = @TenantId

			SELECT @OldProductCount = COUNT(ProductSetItemId)
			FROM ProductSetItems WITH (NOLOCK)
			WHERE ProductSetId = @ProductSetId

			IF EXISTS (
					SELECT 1
					FROM #ProductList PL
					LEFT JOIN ProductSetItems PSI WITH (NOLOCK) ON PSI.ProductId = PL.ProductId
						AND PSI.ProductSetId = @ProductSetId
					WHERE PSI.ProductId IS NULL
					)
				OR @OldProductCount <> @NewProductCount
				OR EXISTS (
					SELECT 1
					FROM #ProductList PL
					INNER JOIN ProductSetItems PSI WITH (NOLOCK) ON PSI.ProductId = PL.ProductId
						AND PSI.ProductSetId = @ProductSetId
					WHERE ISNULL(PSI.Quantity, 1) <> PL.Quantity
					)
			BEGIN
				DELETE PSI
				FROM ProductSetItems PSI
				INNER JOIN ProductSets PS ON PS.ProductSetId = PSI.ProductSetId
				WHERE PSI.ProductSetId = @ProductSetId
					AND PS.TenantId = @TenantId
					AND PS.IsDeleted = 0

				INSERT INTO ProductSetItems (
					ProductSetId
					,ProductId
					,Quantity
					,CreatedBy
					,CreatedDate
					,CreatedUTCDate
					)
				SELECT @ProductSetId
					,ProductId
					,Quantity
					,@UserId
					,@dt
					,@dtUTC
				FROM #ProductList
				ORDER BY ProductId
			END

			--SET @NewProductSetId = @ProductSetId
			SET @Status = 1
			SET @Message = 'Product Set updated successfully'
		END

		--IF ISNULL(@NewProductSetId, 0) = 0
		--BEGIN
		--	SET @Status = 0
		--	SET @Message = 'Invalid Request'
		--END
		--Delete images removed by the user
		IF ISNULL(@DeletedImageIds, '') <> ''
		BEGIN
			DELETE
			FROM ProductSetImage
			WHERE ProductSetImageID IN (
					SELECT CAST(value AS BIGINT)
					FROM STRING_SPLIT(@DeletedImageIds, ',')
					)
		END

		--Insert newly uploaded images from comma separated list
		IF ISNULL(@ProductSetImages, '') <> ''
		BEGIN
			DROP TABLE IF EXISTS #ImageList;

				SELECT LTRIM(RTRIM(value)) AS ImagePath
				INTO #ImageList
				FROM STRING_SPLIT(@ProductSetImages, ',');

			INSERT INTO ProductSetImage (
				ProductSetId
				,ImagePath
				,IsCover
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			SELECT @ProductSetId
				,ImagePath
				,CASE 
					WHEN ImagePath = @SetImage
						THEN 1
					ELSE 0
					END
				,@UserId
				,@dt
				,@dtUTC
			FROM #ImageList;
		END

		--Synchronize the IsCover flag for all images of this set
		UPDATE ProductSetImage
		SET IsCover = CASE 
				WHEN ImagePath = @SetImage
					THEN 1
				ELSE 0
				END
		WHERE ProductSetId = @ProductSetId

		COMMIT TRAN SaveProductSets;

		SELECT @ProductSetId AS ProductSetId
			,@Status AS [Status]
			,@Message AS [Message]
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN SaveProductSets;

		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		SELECT 0 AS [Status]
			,ERROR_MESSAGE() AS [Message];
	END CATCH
END

GO

