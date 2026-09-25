CREATE VIEW dbo.UT_Missing_RawMaterial
WITH ENCRYPTION
AS
select p.TenantID, p.ProductID, p.ProductTitle,p.ModelNo, p.CostPrice, pm.SubjectID AS RawMaterialID
	FROM [dbo].[ProductMaterials] pm
	INNER JOIN Products p ON p.ProductID = pm.ProductID
	INNER JOIN SubjectTypes st ON st.SubjectTypeID = pm.SubjectTypeID
		AND st.SubjectTypeName = 'RawMaterials'
	WHERE SubjectID NOT IN(
		select r.RawMaterialID
		FROM RawMaterials r
		WHERE r.TenantID = p.TenantID
	)

GO

