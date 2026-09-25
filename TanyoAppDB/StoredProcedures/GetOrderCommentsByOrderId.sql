/*
EXEC GetOrderCommentsByOrderId @OrderId = 260756
*/
CREATE PROCEDURE [dbo].[GetOrderCommentsByOrderId] 
(@OrderId BIGINT)
WITH ENCRYPTION
AS
BEGIN
	BEGIN TRY
		SELECT OC.OrderCommentId
			,OC.STATUS
			,OC.Comments
			,OC.CreatedBy AS CreatedByUserId
			,AU.FirstName + ' ' + AU.LastName AS CreatedByName
			,OC.CreatedDate
		FROM OrderComments OC WITH (NOLOCK)
		INNER JOIN AspNetUsers AU WITH (NOLOCK) ON OC.CreatedBy = AU.UserId
		WHERE OC.OrderId = @OrderId
		ORDER BY OC.OrderCommentId DESC
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

