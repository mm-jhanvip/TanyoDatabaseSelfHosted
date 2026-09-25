CREATE PROCEDURE [dbo].[SaveOrderComment] (
	@OrderId BIGINT
	,@Status INT
	,@Comment NVARCHAR(MAX) = NULL
	,@Remarks NVARCHAR(MAX) = NULL
	,@CreatedBy INT
	,@CreatedDate DATETIMEOFFSET
	,@CreatedUTCDate DATETIME
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF ISNULL(@Comment, '') <> ''
		BEGIN
			INSERT INTO dbo.OrderComments (
				OrderId
				,Status
				,Comments
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				)
			VALUES (
				@OrderId
				,@Status
				,@Comment
				,@CreatedBy
				,@CreatedDate
				,@CreatedUTCDate
				);
		END

		IF ISNULL(@Remarks, '') <> ''
		BEGIN
			INSERT INTO dbo.OrderComments (
				OrderId
				,Status
				,Comments
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				,Remarks
				)
			VALUES (
				@OrderId
				,@Status
				,''
				,@CreatedBy
				,@CreatedDate
				,@CreatedUTCDate
				,@Remarks
				);
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

