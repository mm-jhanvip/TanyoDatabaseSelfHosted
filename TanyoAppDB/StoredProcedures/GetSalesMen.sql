--GetSalesMen  2
CREATE PROC [dbo].[GetSalesMen] 
 @TenantID INT
WITH ENCRYPTION
AS
BEGIN

 SELECT au.UserId
  ,au.FirstName + ' ' + au.LastName AS SalesmanName
  ,au.IsDeleted
 FROM AspNetRoles ar
 INNER JOIN AspNetUserRoles aur ON ar.Id = aur.RoleId
 INNER JOIN AspNetUsers au ON aur.UserId = au.Id
 WHERE ar.TenantId = @TenantID
 AND ar.IsDeleted = 0
 AND au.IsActive = 1
 AND (ar.Name NOT LIKE 'Contractor%' AND ar.Name NOT LIKE 'Supervisor%' AND ar.Name NOT LIKE 'SystemUser%')

 UNION ALL

 SELECT au.UserId
  ,au.FirstName + ' ' + au.LastName + ' (Inactive)' AS SalesmanName
  ,au.IsDeleted
 FROM AspNetRoles ar
 INNER JOIN AspNetUserRoles aur ON ar.Id = aur.RoleId
 INNER JOIN AspNetUsers au ON aur.UserId = au.Id
 WHERE ar.TenantId = @TenantID
 AND au.IsDeleted = 1
 AND (ar.Name NOT LIKE 'Contractor%' AND ar.Name NOT LIKE 'Supervisor%' AND ar.Name NOT LIKE 'SystemUser%')
 ORDER BY 3, 2

 --SELECT au.UserId,
 --  au.FirstName + ' ' + au.LastName As SalesmanName
 --FROM AspNetRoles ar 
 --INNER JOIN  AspNetUserRoles aur on ar.Id = aur.RoleId  
 --INNER JOIN AspNetUsers au on aur.UserId = au.Id
 --WHERE ar.Name like 'SalesRepresentative%'
 --AND ar.TenantId=@TenantID
 --AND ar.IsDeleted = 0
 --AND au.IsActive=1
 --UNION ALL
 --SELECT au.UserId,
 --  au.FirstName + ' ' + au.LastName As SalesmanName
 --FROM AspNetRoles ar 
 --INNER JOIN  AspNetUserRoles aur on ar.Id = aur.RoleId  
 --INNER JOIN AspNetUsers au on aur.UserId = au.Id
 --WHERE ar.Name NOT like 'SalesRepresentative%'
 --AND ar.TenantId=@TenantID
 --AND ar.IsDeleted = 0
 --AND au.IsActive=1
 --AND EXISTS( 
 -- select 1
 -- from Orders o (NOLOCK)
 -- WHERE o.TenantId = @TenantID
 -- ANd o.SalesmanId = au.UserId
 --)
 --ORDER BY 2
END

GO

