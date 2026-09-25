-- =============================================
-- Author		: MidCapERP
-- Create date	: 2026-Aug-25
-- Description	: Get order feedback comment and average rating by OrderId
-- =============================================
/*
	EXEC [dbo].[GetOrderFeedbackByOrderId] @OrderId = 260756
*/
CREATE PROCEDURE [dbo].[GetOrderFeedbackByOrderId] 
(@OrderId BIGINT)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		SELECT ISNULL((
					SELECT TOP (1) FC.Comment
					FROM FeedbackComments FC WITH (NOLOCK)
					WHERE FC.OrderId = @OrderId
					), '') AS FeedBackComments
			,ISNULL((
					SELECT CAST(AVG(CAST(FO.FeedbackValue AS DECIMAL(18, 2))) AS DECIMAL(18, 2))
					FROM FeedbackOrders FO WITH (NOLOCK)
					WHERE FO.OrderId = @OrderId
					), 0) AS FeedbackValue
			,ISNULL((
					SELECT COUNT(1)
					FROM FeedbackOrders FO WITH (NOLOCK)
					WHERE FO.OrderId = @OrderId
					), 0) AS FeedbackCount
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

