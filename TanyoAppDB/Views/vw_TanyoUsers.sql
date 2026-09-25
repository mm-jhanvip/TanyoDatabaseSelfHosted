


--select * from vw_TanyoUsers ORDER BY TenantName
CREATE VIEW [dbo].[vw_TanyoUsers]
WITH ENCRYPTION
AS
	select t.TenantId, t.TenantName, u.Email, u.PhoneNumber, t.MasterOTP 
			,r.NormalizedName
			,ur.RoleID
			,u.UserId
	from AspnetUsers u 
	INNER JOIN UserTenantMapping um ON um.UserId = u.UserId
	INNER JOIN Tenants t ON t.TenantId = um.TenantId
	INNER JOIN AspNetUserRoles ur on ur.UserId = u.Id
	INNER JOIN AspNetRoles r ON r.Id = ur.RoleId
	WHERE t.IsDeleted = 0
	AND u.IsActive=1

GO

