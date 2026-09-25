CREATE   PROCEDURE [dbo].[ReportVendorLedger] (
	@VendorId BIGINT
	,@TenantId INT
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	)
WITH ENCRYPTION
AS
BEGIN
   SET NOCOUNT ON;

    BEGIN TRY

	DECLARE @VendorName NVARCHAR(200)
		,@TotalDebitAmount DECIMAL(18, 2)
		,@TotalCreditAmount DECIMAL(18, 2)
		,@OutstandingAmount DECIMAL(18, 2)
		,@FinalJson NVARCHAR(MAX);

	CREATE TABLE #POProducts (
		POProductId BIGINT
		,VendorId BIGINT
		,OrderDate DATE
		,PONumber NVARCHAR(50)
		,DebitAmount DECIMAL(18, 2)
		);

	CREATE TABLE #POProductPayment (
		POProductPaymentId BIGINT
		,POProductId BIGINT
		,PaymentDate DATE
		,CreditAmount DECIMAL(18, 2)
		,PaymentType NVARCHAR(50)
		);

	INSERT INTO #POProducts (
		POProductId
		,VendorId
		,OrderDate
		,PONumber
		,DebitAmount
		)
	SELECT POProductId
		,VendorId
		,OrderDate
		,PONumber
		,TotalAmount
	FROM POProducts WITH (NOLOCK)
	WHERE TenantId = @TenantId
		AND VendorId = @VendorId
		AND (
			CAST(OrderDate AS DATE) BETWEEN @FromDate
				AND @ToDate
			OR (
				@FromDate IS NULL
				AND @ToDate IS NULL
				)
			)
		AND IsDeleted = 0;

	INSERT INTO #POProductPayment (
		POProductId
		,CreditAmount
		)
	SELECT POProductId
		,SUM(ReceivedAmount)
	FROM POProductPayment WITH (NOLOCK)
	WHERE TenantId = @TenantId
		AND POProductId IN (
			SELECT POProductId
			FROM #POProducts
			)
		AND IsDeleted = 0
		AND PaymentStatus = 1
	GROUP BY POProductId ;

	SELECT @VendorName = VendorName
	FROM Vendors WITH (NOLOCK)
	WHERE VendorId = @VendorId
		AND TenantId = @TenantId;

	SELECT @TotalDebitAmount = SUM(ISNULL(DebitAmount, 0))
	FROM #POProducts;

	SELECT @TotalCreditAmount = SUM(ISNULL(CreditAmount, 0))
	FROM #POProductPayment;

	SET @OutstandingAmount = ISNULL(@TotalDebitAmount, 0) - ISNULL(@TotalCreditAmount, 0);

	SELECT PO.POProductId
		,ISNULL(@VendorName, '') AS VendorName
		,ISNULL(@TotalDebitAmount, 0) AS TotalDebitAmount
		,ISNULL(@TotalCreditAmount, 0) AS TotalCreditAmount
		,ISNULL(@OutstandingAmount, 0) AS OutstandingAmount
		,PO.PONumber AS PONumber
		,PO.OrderDate AS OrderDate
		,PO.DebitAmount AS DebitAmount
		,p.CreditAmount AS CreditAmount
	FROM #POProducts PO
	LEFT JOIN #POProductPayment P ON PO.POProductId = P.POProductId

	DROP TABLE IF EXISTS #POProducts;
	
	DROP TABLE IF EXISTS #POProductPayment;

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

