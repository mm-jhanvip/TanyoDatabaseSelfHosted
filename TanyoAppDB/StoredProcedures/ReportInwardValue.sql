-- =============================================  
--Author		: kishan kalena
--Create date	: 08-09-2023
--Description	: Report - Inward Value
-- =============================================
/*
 EXEC ReportInwardValue
	@TenantId = 1
	,@FromDate = '2024-02-26'
	,@ToDate = '2024-02-26'
	,@VendorIDs = NULL
	,@PageIndex = 1
	,@PageSize = 1
	,@SortBy = ''
	,@SortOrder = 'asc'
*/

CREATE PROCEDURE [dbo].[ReportInwardValue] (
	@TenantId INT
	,@FromDate DATE
	,@ToDate DATE
	,@VendorIDs VARCHAR(500) = NULL
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@SortBy VARCHAR(50) = 'InwardGood'
	,@SortOrder VARCHAR(50) = 'ASC'
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT COUNT(DISTINCT ie.InwardId) AS InwardGood,
			COALESCE(SUM(ied.InwardItem), 0) AS InwardItem,
			COALESCE(SUM(ied.TotalAmount), 0) AS TotalAmount,
			COUNT(1) OVER (PARTITION BY 1) AS TotalCount
		FROM 
			InwardEntry ie
			LEFT JOIN ( SELECT InwardId, COUNT(InwardDetailsId) AS InwardItem, SUM(Amount) AS TotalAmount FROM InwardDetailsEntry
			WHERE 
				IsDeleted = 0
			GROUP BY 
				InwardId
		) ied ON ie.InwardId = ied.InwardId
		WHERE 
			ie.IsDeleted = 0 
			AND (@FromDate IS NULL OR CONVERT(DATE, ie.CreatedDate) >= @FromDate)
			AND (@ToDate IS NULL OR CONVERT(DATE, ie.CreatedDate) <= @ToDate)
			AND (@VendorIDs IS NULL OR ie.VendorId IN (SELECT value FROM STRING_SPLIT(@VendorIDs, ',')))
			AND ie.TenantId = @TenantId;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()
			,@ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog
			@ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage 

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

