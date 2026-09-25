


--select * from UT_IncorrectSaleableQuantity order by TenantName
CREATE VIEW [dbo].[UT_IncorrectSaleableQuantity]
WITH ENCRYPTION
AS
with cte as (
select 
	t.TenantName
	,t.TenantId
	,pq.ProductID, 
	p.ProductTitle, p.ModelNo
	,p.Status
	

	,pq.Quantity AS SalebleQuantity,  
	dbo.[fn_SaleableQuantityByWarehouse](pq.ProductID) AS WareHouseQuantity
from ProductQuantities pq
INNER JOIN Products p  ON p.ProductId = pq.ProductId
	AND p.Status NOT IN(3)
INNER JOIN Tenants t ON t.TenantId = p.TenantId
where pq.Quantity>0
and t.TenantId <> 172 --CityArt Wakaner
--WHERE pq.Quantity <> dbo.[fn_SaleableQuantityByWarehouse](pq.ProductID)
)
select * 
from cte
where SalebleQuantity <> WareHouseQuantity

GO

