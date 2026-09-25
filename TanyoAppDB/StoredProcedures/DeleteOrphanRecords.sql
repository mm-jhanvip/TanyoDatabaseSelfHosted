
CREATE PROCEDURE [dbo].[DeleteOrphanRecords]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ObjectName VARCHAR(500)
		,@ErrorMsg VARCHAR(MAX);

	BEGIN TRY
		-------------------------------------------------------
		-- Delete ProductImages
		-------------------------------------------------------
		DECLARE @Tmp_DeletedRecordCount AS TABLE (
			Id INT IDENTITY(1, 1) PRIMARY KEY
			,TableName VARCHAR(100)
			,DeletedCount INT
			)
		DECLARE @DeletedCount INT;

		DELETE PI
		--OUTPUT 'ProductImages'
		-- ,DELETED.ProductId
		--INTO #DeletedProducts(TableName, ProductId)
		FROM ProductImages PI
		WHERE NOT EXISTS (
				SELECT 1
				FROM Products P WITH (NOLOCK)
				WHERE P.ProductId = PI.ProductId
				);

		SET @DeletedCount = @@ROWCOUNT;

		INSERT INTO @Tmp_DeletedRecordCount (
			TableName
			,DeletedCount
			)
		VALUES (
			'Orphan_ProductImages'
			,@DeletedCount
			);

		SET @DeletedCount = 0;

		-------------------------------------------------------
		-- Delete ProductQuantitiesByWarehouse
		-------------------------------------------------------
		DELETE PQBW
		--OUTPUT 'ProductQuantitiesByWarehouse'
		-- ,DELETED.ProductId
		--INTO #DeletedProducts(TableName, ProductId)
		FROM ProductQuantitiesByWarehouse PQBW
		WHERE NOT EXISTS (
				SELECT 1
				FROM Products P WITH (NOLOCK)
				WHERE P.ProductId = PQBW.ProductId
				);

		SET @DeletedCount = @@ROWCOUNT;

		INSERT INTO @Tmp_DeletedRecordCount (
			TableName
			,DeletedCount
			)
		VALUES (
			'Orphan_ProductQuantitiesByWarehouse'
			,@DeletedCount
			);

		SET @DeletedCount = 0;

		-------------------------------------------------------
		-- Delete ProductQuantities
		-------------------------------------------------------
		DELETE PQ
		--OUTPUT 'ProductQuantities'
		-- ,DELETED.ProductId
		--INTO #DeletedProducts(TableName, ProductId)
		FROM ProductQuantities PQ
		WHERE NOT EXISTS (
				SELECT 1
				FROM Products P WITH (NOLOCK)
				WHERE P.ProductId = PQ.ProductId
				);

		SET @DeletedCount = @@ROWCOUNT;

		INSERT INTO @Tmp_DeletedRecordCount (
			TableName
			,DeletedCount
			)
		VALUES (
			'Orphan_ProductQuantities'
			,@DeletedCount
			);

		SET @DeletedCount = 0;

		SELECT *
		FROM @Tmp_DeletedRecordCount;
			---------------------------------------------------------
			---- Activity Logs
			---------------------------------------------------------
			--SELECT @MaxCount = COUNT(*)
			--FROM #DeletedProducts;
			--WHILE @Counter <= @MaxCount
			--BEGIN
			-- SELECT @TableName = TableName
			--  ,@ProductId = ProductId
			-- FROM #DeletedProducts
			-- WHERE Id = @Counter;
			-- DECLARE @Description NVARCHAR(MAX);
			-- SET @Description = CONCAT ('Deleted orphan product records. ',@TableName,' ProductId = ',CAST(@ProductId AS VARCHAR(20)));
			-- EXEC dbo.SaveActivityLog @SubjectTypeId = @SubjectTypeId
			--  ,@SubjectId = @ProductId
			--  ,@Description = @Description
			--  ,@Action = 'DELETE'
			--  ,@CreatedBy = 0
			--  ,@CreatedDate = @CreatedDate
			--  ,@CreatedUTCDate = @CreatedUTCDate;
			-- SET @Counter = @Counter + 1;
			--END;
	END TRY

	BEGIN CATCH
		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;

		THROW;
	END CATCH
END

GO

