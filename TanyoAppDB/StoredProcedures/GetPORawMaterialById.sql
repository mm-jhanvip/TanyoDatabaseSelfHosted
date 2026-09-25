/*
	EXEC [dbo].[GetPORawMaterialById]
		@PORawMaterialId = 1
		,@TenantId = 125
*/
CREATE   PROC [dbo].[GetPORawMaterialById]
(
	@PORawMaterialId BIGINT
	,@TenantId BIGINT
)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @VendorId BIGINT

	SELECT @VendorId = p.VendorId
	FROM dbo.PORawMaterials p WITH (NOLOCK)
	WHERE p.PORawMaterialId = @PORawMaterialId
	AND p.TenantId = @TenantId
	AND p.IsDeleted = 0

	SELECT p.PORawMaterialId
		,p.VendorId
		,v.VendorName
		,p.PONumber
		,p.OrderDate
		,p.Status
		,CASE 
			WHEN p.Status = 1 THEN 'Pending'
			WHEN p.Status = 2 THEN 'InProgress'
			WHEN p.Status = 3 THEN 'Completed'
			ELSE ''
		 END AS StatusName
		,MAX(p.TotalAmount) AS TotalAmount
		,(
			SELECT i.PORawMaterialItemId
				,i.RawMaterialId
				,rw.Title AS RawMaterialTitle
				,rw.ImagePath AS RawMaterialImage
				,i.Quantity
				,i.UnitPrice AS VendorRawMaterialPrice
				,i.ExpectedDeliveryDate
				,i.Status
				,CASE 
					WHEN i.Status = 1 THEN 'Pending'
					WHEN i.Status = 2 THEN 'InProgress'
					WHEN i.Status = 3 THEN 'Completed'
					ELSE ''
				 END AS ItemStatusName
				,i.TotalPrice AS TotalPrice
				,i.Remarks
			FROM dbo.PORawMaterialItems i WITH (NOLOCK)
			INNER JOIN RawMaterials rw WITH (NOLOCK) ON rw.RawMaterialId = i.RawMaterialId
				AND rw.TenantId = @TenantId
				AND rw.IsDeleted = 0
			WHERE i.PORawMaterialId = @PORawMaterialId
			FOR JSON PATH
		) AS PORawMaterialItems
	FROM dbo.PORawMaterials p WITH (NOLOCK)
	INNER JOIN dbo.Vendors v WITH (NOLOCK) ON p.VendorId = v.VendorId
	WHERE p.PORawMaterialId = @PORawMaterialId
	AND p.TenantId = @TenantId
	AND p.IsDeleted = 0
	GROUP BY 
		p.PORawMaterialId, p.VendorId, v.VendorName, p.PONumber, p.OrderDate, p.Status
END

GO

