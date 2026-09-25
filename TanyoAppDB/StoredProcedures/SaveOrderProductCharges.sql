CREATE     PROCEDURE [dbo].[SaveOrderProductCharges]
(
	@TenantID INT
	,@UserID BIGINT
	,@OrderID BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		DECLARE @DateUtc DATETIME = GETUTCDATE()
			,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@LabourSubjectTypeId BIGINT
			,@ProductSubjectTypeId BIGINT
			,@RawMaterialSubjectTypeId BIGINT
			,@PolishSubjectTypeId BIGINT

		SELECT @ProductSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'Products'

		SELECT @LabourSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'Labours'
		--Delete OrderProductCharges
		DELETE FROM dbo.OrderProductCharges
		WHERE OrderId = @OrderID
		
		SELECT @RawMaterialSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'RawMaterials'

		SELECT @PolishSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantID
		AND st.SubjectTypeName = 'Polish'

		--Add RawMaterials in OrderProductCharges
		INSERT INTO dbo.OrderProductCharges
		(
			OrderId
			,OrderSetItemId
			,EntityTypeId
			,EntityId
			,Price
			,CreatedBy
			,CreatedDate
			,CreatedUTCDate
		)
		SELECT @OrderID
			,osi.OrderSetItemId
			,pm.SubjectTypeId
			,pm.SubjectId
			,pm.Qty * rm.UnitPrice AS Price
			,@UserID
			,@DateOffset
			,@DateUtc
		FROM OrderSetItems osi WITH (NOLOCK)
		INNER JOIN ProductMaterials pm WITH (NOLOCK) ON pm.ProductId = osi.SubjectId
		INNER JOIN RawMaterials rm WITH (NOLOCK) ON rm.RawMaterialId = pm.SubjectId
		WHERE osi.OrderId = @OrderID
		AND osi.SubjectTypeId = @ProductSubjectTypeId
		AND pm.SubjectTypeId = @RawMaterialSubjectTypeId
 
		--Add Polish in OrderProductCharges
		INSERT INTO dbo.OrderProductCharges
		(
			OrderId
			,OrderSetItemId
			,EntityTypeId
			,EntityId
			,Price
			,CreatedBy
			,CreatedDate
			,CreatedUTCDate
		)
		SELECT @OrderID
			,osi.OrderSetItemId
			,pm.SubjectTypeId
			,pm.SubjectId
			,pm.Qty * p.UnitPrice AS Price
			,@UserID
			,@DateOffset
			,@DateUtc
		FROM OrderSetItems osi WITH (NOLOCK)
		INNER JOIN ProductMaterials pm WITH (NOLOCK) ON pm.ProductId = osi.SubjectId
		INNER JOIN Polish p WITH (NOLOCK) ON p.PolishId = pm.SubjectId
		WHERE osi.OrderId = @OrderID
		AND osi.SubjectTypeId = @ProductSubjectTypeId
		AND pm.SubjectTypeId = @PolishSubjectTypeId
 
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

