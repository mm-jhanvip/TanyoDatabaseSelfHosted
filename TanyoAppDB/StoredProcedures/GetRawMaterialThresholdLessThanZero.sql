
-- =============================================
-- Author:		<Author,,MAGNUSMINDS>
-- Create date: <Create Date,2024-11-05,>
-- Description:	<Description,,>
/*
EXEC [dbo].[GetRawMaterialThresholdLessThanZero] 
	@TenantId = 1
*/

-- =============================================
CREATE   PROCEDURE [dbo].[GetRawMaterialThresholdLessThanZero] (@TenantId BIGINT = 1)
WITH ENCRYPTION
AS
BEGIN
	SELECT rm.RawMaterialId
		,rm.Title
		,rm.ImagePath
		,rm.UnitPrice
		,rmi.Inventory [StockonHand]
		,rmi.MinimumLimit
		,rmi.InventoryDate [InventoryDate]
		,(au.FirstName + ' ' + au.LastName) [LastModifiedBy]
	FROM RawMaterials rm WITH (NOLOCK)
	INNER JOIN RawMaterialInventory rmi WITH (NOLOCK) ON rm.RawMaterialId = rmi.RawMaterialId
		AND rm.TenantId = @TenantId
		AND rm.IsDeleted = 0
		AND rmi.Inventory <= rmi.MinimumLimit
	INNER JOIN AspNetUsers au WITH (NOLOCK) ON rmi.LastModifiedBy = au.UserId
	ORDER BY rm.Title
END

GO

