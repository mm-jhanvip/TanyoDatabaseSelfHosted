/*
EXEC [dbo].[ApplyOffer_V2]
  @OfferId = 3337
  ,@ProductIds = null
  ,@TenantId = 1207
  ,@UserId = 13305
   ,@IsPublished = 0
*/
CREATE PROCEDURE [dbo].[ApplyOffer_V2] (
	@OfferId BIGINT   
	,@ProductIds NVARCHAR(MAX) = NULL
	,@TenantId BIGINT   
	,@UserId BIGINT
	,@IsPublished BIT = NULL
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		   DECLARE @Result INT;

		-- Populate Product Offers
		EXEC [dbo].[PopulateProductOffers] 
			 @TenantId = @TenantId
			,@OfferId = @OfferId
			,@ProductIds = @ProductIds;

		-- Update Product Offer Price
		EXEC [dbo].[UpdateProductOfferPrice] 
			 @TenantId = @TenantId
			,@UserID = @UserId
			,@OfferId = @OfferId
			,@ProductIds = @ProductIds
			,@IsPublished = @IsPublished
			,@Result = @Result OUTPUT;

		-- Save Announcement
		EXEC [dbo].[SaveOfferAnnouncement] 
			 @OfferId = @OfferId
			,@TenantId = @TenantId
			,@UserId = @UserId
			,@IsPublished = @IsPublished;
	END TRY

	BEGIN CATCH
		   
		IF @@TRANCOUNT > 0
			ROLLBACK;

		DECLARE @ObjectName VARCHAR(500)       
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog 
		     @ObjectName = @ObjectName       
			,@ErrorMsg = @ErrorMsg;

	END CATCH
END

GO

