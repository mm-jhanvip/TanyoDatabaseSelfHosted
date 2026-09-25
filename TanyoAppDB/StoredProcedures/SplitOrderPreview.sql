/*
	EXEC dbo.SplitOrderPreview
		@TenantId  = 125
		,@OrderId = 41711
		,@MaxSplitAmount = 20000
*/
CREATE PROCEDURE [dbo].[SplitOrderPreview] (
	@TenantId INT
	,@OrderId BIGINT
	,@MaxSplitAmount DECIMAL(18, 2)
	)
WITH ENCRYPTION
AS
BEGIN
    BEGIN TRY
	--DECLARE @OrderId BIGINT = 179647
	--	,@TenantId INT = 1;
	DECLARE @AmountBeforeGST DECIMAL(18, 2)
		,@OrderCount INT
		--,@MaxSplitAmount DECIMAL(18, 2) = 200000
		,@TargetSplitAmount DECIMAL(18, 2)
		,@Inc INT = 1
		,@SplitRunningAmount DECIMAL(18, 2)
		,@OrderSetItemId BIGINT
		,@SubjectId BIGINT
		,@SubjectTypeId INT
		,@RemainingQty INT
		,@UnitAmount DECIMAL(18, 2)
		,@TakeQty INT
		,@CurrentItemId BIGINT
		,@MaxSetAmount DECIMAL(18, 2)
		,@QtySplitCount INT
		,@cnt INT = 1
		,@SplitOrderSetItemId BIGINT
		,@OriginalQty NUMERIC(18, 2)
		,@Id INT
		,@ProductSubjectTypeId INT
		,@PaymentAmount NUMERIC (18,2)
		,@PaymentByOrder NUMERIC (18,2)
		,@DeliveryCharge INT
		,@DeliveryAmountCollectionType INT
		,@DeliveryAmount NUMERIC (18,2)
		,@DeliveryAmountByOrder NUMERIC (18,2)
		,@ParentOrderSetItemId BIGINT;		


	DROP TABLE IF EXISTS #OrderDetails;
		
	DROP TABLE IF EXISTS #OrderSetItemDetails;
	
	DROP TABLE IF EXISTS #RemainingItems;
		
	DROP TABLE IF EXISTS #SplitPreview;
	
	DROP TABLE IF EXISTS #SplitByQuantity;
		
	DROP TABLE IF EXISTS #TotalAmountBySplit;
	
	DROP TABLE IF EXISTS #CalculateQuantity;
		
	DROP TABLE IF EXISTS #SplitPreviewFinal;

	DROP TABLE IF EXISTS #AddOns

		SELECT @ProductSubjectTypeId = SubjectTypeId
		FROM SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId

	SELECT ORD.*
		,ISNULL(C.FirstName, '') AS CustomerFirstName
		,ISNULL(C.LastName, '') AS CustomerLastName
	INTO #OrderDetails
	FROM Orders ORD WITH (NOLOCK)
	INNER JOIN Customers C ON C.CustomerId = ORD.CustomerId
	WHERE OrderId = @OrderId;

	SELECT *
		,Discount / Quantity AS DicountPerItem
	INTO #OrderSetItemDetails
	FROM OrderSetItems WITH (NOLOCK)
	WHERE OrderId = @OrderId
		AND IsDeleted = 0;

	SELECT @PaymentAmount = SUM(ReceivedAmount)
	FROM Payments WITH (NOLOCK)
	WHERE OrderId = @OrderId
	AND IsDeleted = 0
	GROUP BY OrderId

	SELECT @DeliveryCharge = DeliveryCharge
	,@DeliveryAmountCollectionType = DeliveryAmountCollectionType
	,@DeliveryAmount = DeliveryAmount
	FROM #OrderDetails 
	

	SELECT @AmountBeforeGST = SUM(AmountBeforeGST)
	FROM #OrderSetItemDetails;

	SELECT @MaxSetAmount = MAX(AmountBeforeGST / Quantity)
	FROM #OrderSetItemDetails

	--IF @MaxSetAmount > @MaxSplitAmount
	--BEGIN
	--	--SET @MaxSplitAmount = @MaxSetAmount
	--	SELECT @OrderCount = CEILING(@AmountBeforeGST / @MaxSplitAmount);
	--		--SET @MaxSplitAmount = ROUND(@AmountBeforeGST / @OrderCount, 0);
	--END
	--ELSE
	--BEGIN
	--	SELECT @OrderCount = CEILING(@AmountBeforeGST / @MaxSplitAmount);
	--		--SET @MaxSplitAmount = ROUND(@AmountBeforeGST / @OrderCount, 0);
	--END
	SELECT @OrderCount = CEILING(@AmountBeforeGST / @MaxSplitAmount);

	SELECT @PaymentByOrder = @PaymentAmount/@OrderCount

	SELECT @DeliveryAmountByOrder = @DeliveryAmount/@OrderCount

	--SELECT @MaxSplitAmount MaxSplitAmount
	--,@OrderCount AS OrderCount
	--,@MaxSetAmount MaxSetAmount
	--,@AmountBeforeGST AS AmountBeforeGST
	--,@AmountBeforeGST/@MaxSplitAmount AS SetCount
	--,@MaxSplitAmount AS TargetSplitAmount
	SELECT OrderSetItemId
		,SubjectId
		,SubjectTypeId
		,Quantity AS RemainingQty
		,(AmountBeforeGST / NULLIF(Quantity, 0)) AS UnitAmount
	INTO #RemainingItems
	FROM #OrderSetItemDetails;

	CREATE TABLE #CalculateQuantity (
		SplitNo INT
		,OrderSetItemId BIGINT
		,SplitQuantity INT
		)

	CREATE TABLE #SplitPreview (
		SplitNo INT
		,OrderSetItemId BIGINT
		,SubjectId BIGINT
		,SubjectTypeId INT
		,SplitQuantity INT
		,SplitTotalAmount NUMERIC(18, 2)
		);

	CREATE TABLE #SplitByQuantity (
		ID INT IDENTITY(1, 1)
		,OrderSetItemId BIGINT
		,ParentOrderSetItemId BIGINT		
		,SubjectId BIGINT
		,SubjectTypeId INT
		,Quantity NUMERIC(18, 2)
		,AmountBeforeGST DECIMAL(18, 2)
		,UnitAmount DECIMAL(18, 2)
		,IsAdded BIT DEFAULT(0)
		,IsSkipped BIT DEFAULT(0)
		,CheckSet INT DEFAULT(1)
		)

	INSERT INTO #SplitByQuantity (
		OrderSetItemId
		,ParentOrderSetItemId 
		,SubjectId
		,SubjectTypeId
		,Quantity
		,AmountBeforeGST
		,UnitAmount
		)
	SELECT OSI.OrderSetItemId
		,ParentOrderSetItemId 
		,OSI.SubjectId
		,OSI.SubjectTypeId
		,OSI.Quantity
		,OSI.AmountBeforeGST
		,(OSI.AmountBeforeGST / NULLIF(OSI.Quantity, 0)) AS UnitAmount
	FROM #OrderSetItemDetails OSI
	WHERE Quantity = 1
	AND ParentOrderSetItemId IS NULL
	and NOT EXISTS (SELECT 1  
					FROM #OrderSetItemDetails OSID
					WHERE OSID.ParentOrderSetItemId = OSI.OrderSetItemId
					) 
	ORDER BY OrderSetItemId

	SELECT OSI.OrderSetItemId
		,ParentOrderSetItemId 
		,OSI.SubjectId
		,OSI.SubjectTypeId
		,OSI.Quantity
		,OSI.AmountBeforeGST
		,(OSI.AmountBeforeGST / NULLIF(OSI.Quantity, 0)) AS UnitAmount
	INTO #AddOns
	FROM #OrderSetItemDetails OSI
	WHERE  ParentOrderSetItemId IS NOT NULL
	OR EXISTS (SELECT 1  
					FROM #OrderSetItemDetails OSID
					WHERE OSID.ParentOrderSetItemId = OSI.OrderSetItemId
					) 
	ORDER BY OrderSetItemId

	SELECT @QtySplitCount = Count(OrderSetItemId)
	FROM #OrderSetItemDetails
	WHERE Quantity > 1

	WHILE @cnt <= @QtySplitCount
	BEGIN
		SELECT @SplitOrderSetItemId = NULL
			,@OriginalQty = NULL

		SELECT TOP 1 @SplitOrderSetItemId = OrderSetItemId
			,@OriginalQty = Quantity
		FROM #OrderSetItemDetails OSID
		WHERE Quantity > 1
			AND NOT EXISTS (
				SELECT 1
				FROM #SplitByQuantity SBQ
				WHERE SBQ.OrderSetItemId = OSID.OrderSetItemId
				)
			AND ParentOrderSetItemId IS NULL
			AND NOT EXISTS (SELECT 1  
					FROM #OrderSetItemDetails OSITD
					WHERE OSITD.ParentOrderSetItemId = OSID.OrderSetItemId
					) 
		ORDER BY OrderSetItemId

		DECLARE @ItrCnt INT = 1

		WHILE @ItrCnt <= @OriginalQty
		BEGIN
			INSERT INTO #SplitByQuantity (
				OrderSetItemId
				,SubjectId
				,SubjectTypeId
				,Quantity
				,AmountBeforeGST
				,UnitAmount
				)
			SELECT OrderSetItemId
				,SubjectId
				,SubjectTypeId
				,1 Quantity
				,AmountBeforeGST
				,(AmountBeforeGST / NULLIF(Quantity, 0)) AS UnitAmount
			FROM #OrderSetItemDetails
			WHERE Quantity > 1
				AND OrderSetItemId = @SplitOrderSetItemId
			ORDER BY OrderSetItemId

			SET @ItrCnt += 1;
		END

		SET @cnt += 1;
	END

	--SELECT * FROM #SplitByQuantity
	DECLARE @IncFinalOrder INT = 1
	DECLARE @CntFinalOrder INT = 0

	SET @CntFinalOrder = @OrderCount

	WHILE @IncFinalOrder <= @CntFinalOrder
	BEGIN
		--SELECT 1
		DECLARE @IncFinalOrderInner INT = 1
		DECLARE @CntFinalOrderInner INT = 0
		DECLARE @OrderSetItemIdFinal BIGINT
			,@SubjectIdFinal BIGINT
			,@SubjectTypeIdFinal INT
			,@AmountBeforeGSTFinal DECIMAL(18, 2)
			,@UnitAmountFinal DECIMAL(18, 2)
		DECLARE @RunningFinalAmount DECIMAL(18, 2) = 0

		SELECT @CntFinalOrderInner = COUNT(1)
		FROM #SplitByQuantity

		UPDATE SQ
		SET IsSkipped = 0
			,CheckSet = @IncFinalOrder
		FROM #SplitByQuantity SQ
		WHERE CheckSet = @IncFinalOrder - 1

		--UPDATE #SplitByQuantity 
		--SET CheckSet = @IncFinalOrder
		WHILE (@IncFinalOrderInner <= @CntFinalOrderInner)
		BEGIN
			SELECT @OrderSetItemIdFinal = NULL
				,@SubjectIdFinal = NULL
				,@SubjectTypeIdFinal = NULL
				,@AmountBeforeGSTFinal = NULL
				,@UnitAmountFinal = NULL

			SELECT @OrderSetItemIdFinal = OrderSetItemId
				,@SubjectIdFinal = SubjectId
				,@SubjectTypeIdFinal = SubjectTypeId
				,@AmountBeforeGSTFinal = AmountBeforeGST
				,@UnitAmountFinal = UnitAmount
			FROM #SplitByQuantity
			WHERE ID = @IncFinalOrderInner
				AND IsAdded = 0
				AND IsSkipped = 0
				AND CheckSet = @IncFinalOrder

			IF (@OrderSetItemIdFinal > 0)
			BEGIN
				--IF(@IncFinalOrderInner = 1)
				--BEGIN
				--SELECT @MaxSplitAmount,@RunningFinalAmount,@UnitAmountFinal , @RunningFinalAmount + @UnitAmountFinal
				--END
				IF (@MaxSplitAmount >= @RunningFinalAmount + @UnitAmountFinal)
				BEGIN
					IF NOT EXISTS (
							SELECT 1
							FROM #SplitPreview
							WHERE SplitNo = @IncFinalOrder
								AND OrderSetItemId = @OrderSetItemIdFinal
							)
					BEGIN
						INSERT INTO #SplitPreview (
							SplitNo
							,OrderSetItemId
							,SubjectId
							,SubjectTypeId
							,SplitQuantity
							,SplitTotalAmount
							)
						VALUES (
							@IncFinalOrder
							,@OrderSetItemIdFinal
							,@SubjectIdFinal
							,@SubjectTypeIdFinal
							,1
							,@UnitAmountFinal
							);

						UPDATE #SplitByQuantity
						SET IsAdded = 1
						WHERE ID = @IncFinalOrderInner

						SET @RunningFinalAmount = @RunningFinalAmount + @UnitAmountFinal;
					END
					ELSE
					BEGIN
						UPDATE #SplitByQuantity
						SET IsSkipped = 1
						WHERE ID = @IncFinalOrderInner
					END
				END
				ELSE
				BEGIN
					SET @IncFinalOrderInner = @IncFinalOrderInner + 1;

					CONTINUE;
				END
			END
			ELSE
			BEGIN
				SET @IncFinalOrderInner = @IncFinalOrderInner + 1;

				CONTINUE;
			END

			SET @IncFinalOrderInner = @IncFinalOrderInner + 1;
		END


		--UPDATE SQ
		--SET IsSkipped = 0
		--,CheckSet = CheckSet + 1
		--FROM #SplitByQuantity SQ
		--WHERE CheckSet = @IncFinalOrder
		SET @IncFinalOrder = @IncFinalOrder + 1;
	END


	DECLARE @IncFinalOrderForGreaterAmount INT = 1
	DECLARE @CntFinalOrderForGreaterAmount INT = 0
	DECLARE @OrderSetItemIdForGreaterAmount BIGINT
		,@SubjectIdForGreaterAmount BIGINT
		,@SubjectTypeIdForGreaterAmount INT
		,@AmountBeforeGSTForGreaterAmount DECIMAL(18, 2)
		,@UnitAmountForGreaterAmount DECIMAL(18, 2)
	DECLARE @MaxSetNo INT = 0

	SELECT @MaxSetNo = MAX(SplitNo)
	FROM #SplitPreview

	SELECT @CntFinalOrderForGreaterAmount = COUNT(1)
	FROM #SplitByQuantity

	WHILE (@IncFinalOrderForGreaterAmount <= @CntFinalOrderForGreaterAmount)
	BEGIN
		SELECT @OrderSetItemIdForGreaterAmount = NULL
			,@SubjectIdForGreaterAmount = NULL
			,@SubjectTypeIdForGreaterAmount = NULL
			,@AmountBeforeGSTForGreaterAmount = NULL
			,@UnitAmountForGreaterAmount = NULL

		SELECT @OrderSetItemIdForGreaterAmount = OrderSetItemId
			,@SubjectIdForGreaterAmount = SubjectId
			,@SubjectTypeIdForGreaterAmount = SubjectTypeId
			,@AmountBeforeGSTForGreaterAmount = AmountBeforeGST
			,@UnitAmountForGreaterAmount = UnitAmount
		FROM #SplitByQuantity
		WHERE ID = @IncFinalOrderForGreaterAmount
			AND IsAdded = 0
			AND IsSkipped = 0

		IF (@OrderSetItemIdForGreaterAmount > 0)
		BEGIN
			SET @MaxSetNo = ISNULL(@MaxSetNo,0) + 1;

			IF ISNULL(@MaxSetNo,0) > 0
			BEGIN
				INSERT INTO #SplitPreview (
					SplitNo
					,OrderSetItemId
					,SubjectId
					,SubjectTypeId
					,SplitQuantity
					,SplitTotalAmount
					)
				VALUES (
					@MaxSetNo
					,@OrderSetItemIdForGreaterAmount
					,@SubjectIdForGreaterAmount
					,@SubjectTypeIdForGreaterAmount
					,1
					,@UnitAmountForGreaterAmount
					);

				UPDATE #SplitByQuantity
				SET IsAdded = 1
				WHERE ID = @IncFinalOrderForGreaterAmount
			END
		END

		SET @IncFinalOrderForGreaterAmount = @IncFinalOrderForGreaterAmount + 1
	END




	-------------------------------
	DECLARE @IncDuplicateOrer INT = 1
	DECLARE @CntDuplicateOrer INT = 0

	SET @CntDuplicateOrer = @OrderCount

	WHILE @IncDuplicateOrer <= @CntDuplicateOrer
	BEGIN
		--SELECT 1
		DECLARE @IncDuplicateOrerInner INT = 1
		DECLARE @CntDuplicateOrerInner INT = 0
		DECLARE @OrderSetItemIdDuplicateOrer BIGINT
			,@SubjectIdDuplicateOrer BIGINT
			,@SubjectTypeIdDuplicateOrer INT
			,@AmountBeforeGSTDuplicateOrer DECIMAL(18, 2)
			,@UnitAmountDuplicateOrer DECIMAL(18, 2)
		DECLARE @RunningDuplicateOrerFinalAmount DECIMAL(18, 2) = 0

		SELECT @RunningDuplicateOrerFinalAmount = 0

		SELECT @RunningDuplicateOrerFinalAmount = SUM(SplitTotalAmount)
		FROM #SplitPreview
		WHERE SplitNo = @IncDuplicateOrer

		--SELECT @RunningDuplicateOrerFinalAmount
		SELECT @CntDuplicateOrerInner = COUNT(1)
		FROM #SplitByQuantity

		WHILE (@IncDuplicateOrerInner <= @CntDuplicateOrerInner)
		BEGIN
			SELECT @OrderSetItemIdDuplicateOrer = NULL
				,@SubjectIdDuplicateOrer = NULL
				,@SubjectTypeIdDuplicateOrer = NULL
				,@AmountBeforeGSTDuplicateOrer = NULL
				,@UnitAmountDuplicateOrer = NULL

			SELECT @OrderSetItemIdDuplicateOrer = OrderSetItemId
				,@SubjectIdDuplicateOrer = SubjectId
				,@SubjectTypeIdDuplicateOrer = SubjectTypeId
				,@AmountBeforeGSTDuplicateOrer = AmountBeforeGST
				,@UnitAmountDuplicateOrer = UnitAmount
			FROM #SplitByQuantity
			WHERE ID = @IncDuplicateOrerInner
				AND IsSkipped = 1
				AND IsAdded = 0

			IF (@OrderSetItemIdDuplicateOrer > 0)
			BEGIN
				--IF(@IncFinalOrderInner = 1)
				--BEGIN
				--SELECT @MaxSplitAmount,@RunningFinalAmount,@UnitAmountFinal , @RunningFinalAmount + @UnitAmountFinal
				--END
				IF (@MaxSplitAmount >= @RunningDuplicateOrerFinalAmount + @UnitAmountDuplicateOrer)
					AND NOT EXISTS (
						SELECT 1
						FROM #SplitPreview
						WHERE SplitNo = @IncDuplicateOrer
							AND OrderSetItemId = @OrderSetItemIdDuplicateOrer
						)
				BEGIN
					INSERT INTO #SplitPreview (
						SplitNo
						,OrderSetItemId
						,SubjectId
						,SubjectTypeId
						,SplitQuantity
						,SplitTotalAmount
						)
					VALUES (
						@IncDuplicateOrer
						,@OrderSetItemIdDuplicateOrer
						,@SubjectIdDuplicateOrer
						,@SubjectTypeIdDuplicateOrer
						,1
						,@UnitAmountDuplicateOrer
						);

					UPDATE #SplitByQuantity
					SET IsAdded = 1
						,IsSkipped = 0
					WHERE ID = @IncDuplicateOrerInner

					SET @RunningDuplicateOrerFinalAmount = @RunningDuplicateOrerFinalAmount + @UnitAmountDuplicateOrer;
				END
				ELSE
				BEGIN
					SET @IncDuplicateOrerInner = @IncDuplicateOrerInner + 1;

					CONTINUE;
				END
			END
			ELSE
			BEGIN
				SET @IncDuplicateOrerInner = @IncDuplicateOrerInner + 1;

				CONTINUE;
			END

			SET @IncDuplicateOrerInner = @IncDuplicateOrerInner + 1;
		END

		SET @IncDuplicateOrer = @IncDuplicateOrer + 1;
	END


	-------------------------------
	DECLARE @IncDuplicateOrderMin INT = 1
	DECLARE @CntDuplicateOrderMin INT = 0

	SET @CntDuplicateOrderMin = @OrderCount

	WHILE @IncDuplicateOrderMin <= @CntDuplicateOrderMin
	BEGIN
		--SELECT 1
		DECLARE @IncDuplicateOrderInnerMin INT = 1
		DECLARE @CntDuplicateOrderInnerMin INT = 0
		DECLARE @OrderSetItemIdDuplicateOrderMin BIGINT
			,@SubjectIdDuplicateOrderMin BIGINT
			,@SubjectTypeIdDuplicateOrderMin INT
			,@AmountBeforeGSTDuplicateOrderMin DECIMAL(18, 2)
			,@UnitAmountDuplicateOrderMin DECIMAL(18, 2)

		--DECLARE @RunningDuplicateOrderFinalAmountMin DECIMAL(18, 2) = 0
		--SELECT @RunningDuplicateOrderFinalAmountMin = 0
		--SELECT @RunningDuplicateOrderFinalAmountMin = SUM(SplitTotalAmount)
		--FROM #SplitPreview
		--WHERE SplitNo = @IncDuplicateOrderMin
		--SELECT @RunningDuplicateOrderFinalAmountMin
		SELECT @CntDuplicateOrderInnerMin = COUNT(1)
		FROM #SplitByQuantity

		WHILE (@IncDuplicateOrderInnerMin <= @CntDuplicateOrderInnerMin)
		BEGIN
			SELECT @OrderSetItemIdDuplicateOrderMin = NULL
				,@SubjectIdDuplicateOrderMin = NULL
				,@SubjectTypeIdDuplicateOrderMin = NULL
				,@AmountBeforeGSTDuplicateOrderMin = NULL
				,@UnitAmountDuplicateOrderMin = NULL

			SELECT @OrderSetItemIdDuplicateOrderMin = OrderSetItemId
				,@SubjectIdDuplicateOrderMin = SubjectId
				,@SubjectTypeIdDuplicateOrderMin = SubjectTypeId
				,@AmountBeforeGSTDuplicateOrderMin = AmountBeforeGST
				,@UnitAmountDuplicateOrderMin = UnitAmount
			FROM #SplitByQuantity
			WHERE ID = @IncDuplicateOrderInnerMin
				AND IsSkipped = 1
				AND IsAdded = 0

			TRUNCATE TABLE #CalculateQuantity

			INSERT INTO #CalculateQuantity (
				SplitNo
				,OrderSetItemId
				,SplitQuantity
				)
			SELECT SplitNo
				,OrderSetItemId
				,SUM(SplitQuantity) AS SplitQuantity
			FROM #SplitPreview
			GROUP BY SplitNo
				,OrderSetItemId

			DECLARE @RunningDuplicateOrderFinalAmountMin DECIMAL(18, 2) = 0
				,@MinSetNo INT = 0

			SELECT @RunningDuplicateOrderFinalAmountMin = 0

			SELECT @MinSetNo = 0

			SELECT @MinSetNo = SplitNo
			FROM #CalculateQuantity
			WHERE OrderSetItemId = @OrderSetItemIdDuplicateOrderMin
				AND SplitQuantity = (
					SELECT MIN(SplitQuantity)
					FROM #CalculateQuantity
					WHERE OrderSetItemId = @OrderSetItemIdDuplicateOrderMin
					);

			SELECT @RunningDuplicateOrderFinalAmountMin = SUM(SplitTotalAmount)
			FROM #SplitPreview
			WHERE SplitNo = @MinSetNo

			IF (@OrderSetItemIdDuplicateOrderMin > 0)
			BEGIN
				--IF(@IncFinalOrderInner = 1)
				--BEGIN
				--SELECT @MaxSplitAmount,@RunningFinalAmount,@UnitAmountFinal , @RunningFinalAmount + @UnitAmountFinal
				--END
				IF (@MaxSplitAmount >= @RunningDuplicateOrderFinalAmountMin + @UnitAmountDuplicateOrderMin)
				BEGIN
					INSERT INTO #SplitPreview (
						SplitNo
						,OrderSetItemId
						,SubjectId
						,SubjectTypeId
						,SplitQuantity
						,SplitTotalAmount
						)
					VALUES (
						@MinSetNo
						,@OrderSetItemIdDuplicateOrderMin
						,@SubjectIdDuplicateOrderMin
						,@SubjectTypeIdDuplicateOrderMin
						,1
						,@UnitAmountDuplicateOrderMin
						);

					UPDATE #SplitByQuantity
					SET IsAdded = 1
						,IsSkipped = 0
					WHERE ID = @IncDuplicateOrderInnerMin

					SET @RunningDuplicateOrderFinalAmountMin = @RunningDuplicateOrderFinalAmountMin + @UnitAmountDuplicateOrderMin;
				END
				ELSE
				BEGIN
					SET @IncDuplicateOrderInnerMin = @IncDuplicateOrderInnerMin + 1;

					CONTINUE;
				END
			END
			ELSE
			BEGIN
				SET @IncDuplicateOrderInnerMin = @IncDuplicateOrderInnerMin + 1;

				CONTINUE;
			END

			SET @IncDuplicateOrderInnerMin = @IncDuplicateOrderInnerMin + 1;
		END

		SET @IncDuplicateOrderMin = @IncDuplicateOrderMin + 1;
	END



	-------------------------------
	DECLARE @IncFinalOrderForGreaterAmountFinal INT = 1
	DECLARE @CntFinalOrderForGreaterAmountFinal INT = 0
	DECLARE @OrderSetItemIdForGreaterAmountFinal BIGINT
		,@SubjectIdForGreaterAmountFinal BIGINT
		,@SubjectTypeIdForGreaterAmountFinal INT
		,@AmountBeforeGSTForGreaterAmountFinal DECIMAL(18, 2)
		,@UnitAmountForGreaterAmountFinal DECIMAL(18, 2)
	DECLARE @MaxFinalSetNo INT = 0

	SELECT @MaxFinalSetNo = MAX(SplitNo)
	FROM #SplitPreview

	SET @MaxFinalSetNo = ISNULL(@MaxFinalSetNo,0) + 1;

	SELECT @CntFinalOrderForGreaterAmountFinal = COUNT(1)
	FROM #SplitByQuantity

	WHILE (@IncFinalOrderForGreaterAmountFinal <= @CntFinalOrderForGreaterAmountFinal)
	BEGIN
		SELECT @OrderSetItemIdForGreaterAmountFinal = NULL
			,@SubjectIdForGreaterAmountFinal = NULL
			,@SubjectTypeIdForGreaterAmountFinal = NULL
			,@AmountBeforeGSTForGreaterAmountFinal = NULL
			,@UnitAmountForGreaterAmountFinal = NULL

		SELECT @OrderSetItemIdForGreaterAmountFinal = OrderSetItemId
			,@SubjectIdForGreaterAmountFinal = SubjectId
			,@SubjectTypeIdForGreaterAmountFinal = SubjectTypeId
			,@AmountBeforeGSTForGreaterAmountFinal = AmountBeforeGST
			,@UnitAmountForGreaterAmountFinal = UnitAmount
		FROM #SplitByQuantity
		WHERE ID = @IncFinalOrderForGreaterAmountFinal
			AND IsAdded = 0
			--AND IsSkipped = 0

		IF (@OrderSetItemIdForGreaterAmountFinal > 0)
		BEGIN


			INSERT INTO #SplitPreview (
				SplitNo
				,OrderSetItemId
				,SubjectId
				,SubjectTypeId
				,SplitQuantity
				,SplitTotalAmount
				)
			VALUES (
				@MaxFinalSetNo
				,@OrderSetItemIdForGreaterAmountFinal
				,@SubjectIdForGreaterAmountFinal
				,@SubjectTypeIdForGreaterAmountFinal
				,1
				,@UnitAmountForGreaterAmountFinal
				);

			UPDATE #SplitByQuantity
			SET IsAdded = 1
			WHERE ID = @IncFinalOrderForGreaterAmountFinal
		END

		SET @IncFinalOrderForGreaterAmountFinal = @IncFinalOrderForGreaterAmountFinal + 1
	END
	-------------------------------
	--AddOns
	-------------------------------
	IF EXISTS (SELECT 1 
			   FROM #AddOns 
			  )
	BEGIN

		DECLARE @MaxAddOnFinalSetNo INT = 0

		SELECT @MaxAddOnFinalSetNo = MAX(SplitNo)
		FROM #SplitPreview

		SET @MaxAddOnFinalSetNo = ISNULL(@MaxAddOnFinalSetNo,0) + 1;

		INSERT INTO #SplitPreview (
			SplitNo
			,OrderSetItemId
			,SubjectId
			,SubjectTypeId
			,SplitQuantity
			,SplitTotalAmount
			)
		SELECT @MaxAddOnFinalSetNo
			,OrderSetItemId
			,SubjectId
			,SubjectTypeId
			,Quantity
			,AmountBeforeGST
		FROM #AddOns


	END
	-------------------------------

	--SELECT * FROM #SplitByQuantity
	SELECT SplitNo
		,SUM(SplitTotalAmount) AS TotalAmount
	INTO #TotalAmountBySplit
	FROM #SplitPreview
	GROUP BY SplitNo

	SELECT SplitNo
		,SP.OrderSetItemId
		,SP.SubjectId
		,SP.SubjectTypeId
		,SUM(SP.SplitQuantity) AS SplitQuantity
		,SUM(SP.SplitTotalAmount) AS SplitTotalAmount
	INTO #SplitPreviewFinal
	FROM #SplitPreview SP
	GROUP BY SplitNo
		,OrderSetItemId
		,SubjectId
		,SubjectTypeId

	--SELECT DISCOUNT/
	--FROM #OrderSetItemDetails OSI 
	--SELECT SplitNo
	--	,COUNT(SplitTotalAmount) AS TotalAmount
	--	,discount
	--INTO #TotalItemCountBySplit
	--FROM #SplitPreview SP
	--GROUP BY SplitNo,OrderSetItemId
	SELECT @OrderId AS OrderId
		,SP.SplitNo
		,SP.OrderSetItemId
		,SP.SubjectId
		,SP.SubjectTypeId
		,PT.ModelNo ProductModelNo
		,OSI.DiscountPrice AS DiscountPercentage
		,CAST(OSI.DicountPerItem AS NUMERIC(18, 2)) * SP.SplitQuantity AS Discount
		,OSI.UnitPrice
		,SP.SplitQuantity
		,SP.SplitTotalAmount
		,TAS.TotalAmount AS OrderTotalAmount
		,PT.ProductTitle
		,ORD.CustomerID
		,ORD.CustomerFirstName
		,ORD.CustomerLastName
		,OSI.Width
		,OSI.Height
		,OSI.Depth
		,OSI.Diameter
		,OSI.InstantWidth
		,OSI.InstantHeight
		,OSI.InstantDepth
		,OSI.InstantDiameter
		,OSI.OfferId
		,ORD.TentativeDeliveryDate
		,ORD.IsFreeDelivery
		,ORD.DeliveryAmountCollectionType
		,OSI.UnitPrice * SP.SplitQuantity AS GrossTotal
		,CAST (
		CASE 
			WHEN ORD.GSTType = 0 
			THEN (OSI.AmountBeforeGST)* (1+(OSI.GST/100))
		ELSE OSI.AmountBeforeGST 
		END
			 AS NUMERIC (18,2)) AS TotalAmount
		,CAST (ROUND((OSI.AmountBeforeGST )* ((OSI.GST/200)),2) AS numeric (18,2)) AS CGSTAmount
		,CAST (ROUND((OSI.AmountBeforeGST )* ((OSI.GST/200)),2) AS numeric (18,2)) AS SGSTAmount
		--,ISNULL(@PaymentByOrder,0) AS OrderPayment
		,CASE WHEN SP.SplitNo = 1 THEN @DeliveryAmount ELSE 0 END AS DeliveryAmount
		,@DeliveryCharge AS DeliveryCharge
		,C.PhoneNumber
		,CAST(CASE 
			WHEN OSI.ParentOrderSetItemId IS NOT NULL 
			THEN 1 
			ELSE 0
			END AS BIT) AS IsAddOn
		,OSI.ParentOrderSetItemId
		,CAST (
		CASE 
			WHEN ORD.GSTType = 0 
			THEN (OSI.AmountBeforeGST)* (1+(OSI.GST/100))
		ELSE OSI.AmountBeforeGST 
		END
			 /NULLIF(sp.SplitQuantity,0) AS NUMERIC (18,2)) AS UnitSalePrice
	FROM #SplitPreviewFinal SP
	INNER JOIN #TotalAmountBySplit TAS ON SP.SplitNo = TAS.SplitNo
	INNER JOIN #OrderSetItemDetails OSI ON OSI.OrderSetItemId = SP.OrderSetItemId
	INNER JOIN Products PT WITH (NOLOCK) ON PT.ProductId = SP.SubjectId
	INNER JOIN #OrderDetails ORD ON ORD.OrderId = OSI.OrderId
	INNER JOIN Customers C ON C.CustomerId = ORD.CustomerID
	WHERE SP.SubjectTypeId = @ProductSubjectTypeId
		--GROUP BY SP.SplitNo
		--	,SP.OrderSetItemId
		--	,SP.SubjectId
		--	,SP.SubjectTypeId
		--	,TAS.TotalAmount
		--	,PT.ProductTitle
		--	,PT.ModelNo
		--	,OSI.DiscountPrice
		--	,OSI.DicountPerItem
		--	,OSI.UnitPrice
		--	,ORD.CustomerID
		--	,ORD.CustomerFirstName
		--	,ORD.CustomerLastName
		--	,OSI.Width
		--	,OSI.Height
		--	,OSI.Depth
		--	,OSI.Diameter
		--	,OSI.InstantWidth
		--	,OSI.InstantHeight
		--	,OSI.InstantDepth
		--	,OSI.InstantDiameter
		--	,OSI.OfferId
		--	,ORD.TentativeDeliveryDate
		--	,ORD.IsFreeDelivery
		--	,ORD.DeliveryAmountCollectionType
		--	,OSI.GrossTotal 
		--	,OSI.TotalAmount
		--	,OSI.CGSTAmount
		--	,OSI.SGSTAmount
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

