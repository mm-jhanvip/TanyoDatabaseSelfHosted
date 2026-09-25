/*  
 EXEC [dbo].[ListOrderDetails]  
  @TenantID = 2  
  ,@OrderNo = NULL  
  ,@SalesmanId = NULL  
  ,@CustomerName = NULL  
  ,@RefferedBy = NULL  
  ,@PhoneNumber = NULL  
  ,@OrderType = NULL  
  ,@InquiryFromDate = NULL  
  ,@InquiryToDate = NULL  
  ,@OrderFromDate = '01-12-2022'  
  ,@OrderToDate = '03-12-2024'  
  ,@DeliveryFromDate = NULL  
  ,@DeliveryToDate = NULL  
  ,@Tags = NULL  
  ,@Status = NULL  
  ,@LocationID = NULL  
  ,@toPrice = null  
  ,@fromPrice = null  
  ,@PageIndex = 1  
  ,@PageSize = 2500  
  ,@SortBy= 'OrderDate'  
  ,@SortOrder = 'DESC'  
*/  
CREATE PROC [dbo].[zListOrderDetails_Backup_20250509]  
(  
 @TenantID BIGINT  
 ,@OrderNo VARCHAR(20) = NULL  
 ,@SalesmanId BIGINT = NULL  
 ,@CustomerName VARCHAR(100) = NULL  
 ,@RefferedBy BIGINT = NULL  
 ,@PhoneNumber VARCHAR(15) = NULL  
 ,@OrderType SMALLINT = NULL  
 ,@InquiryFromDate Date = NULL  
 ,@InquiryToDate Date = NULL  
 ,@OrderFromDate Date = NULL  
 ,@OrderToDate Date = NULL  
 ,@DeliveryFromDate Date = NULL  
 ,@DeliveryToDate Date = NULL  
 ,@Tags BIGINT = NULL  
 ,@Status VARCHAR(50) = NULL  
 ,@LocationID VARCHAR(500) = NULL  
 ,@toPrice INT = NULL  
 ,@fromPrice INT = NULL  
 ,@PageIndex INT = 1  
 ,@PageSize INT = 25  
 ,@SortBy VARCHAR(50) = 'OrderDate'  
 ,@SortOrder VARCHAR(10) = 'ASC'  
 ,@IsStockOnHold BIT = NULL  
)  
WITH ENCRYPTION
AS
BEGIN  
  
 SET NOCOUNT ON;  
  DECLARE @OrderFromDateTime DATETIMEOFFSET = NULL  
  ,@OrderToDateTime DATETIMEOFFSET = NULL  
  ,@InquiryFromDateTime DATETIME = NULL  
  ,@InquiryToDateTime DATETIME = NULL  
  ,@DeliveryFromDateTime DATETIMEOFFSET = NULL  
  ,@DeliveryToDateTime DATETIMEOFFSET = NULL  
  
 DECLARE @TenantGSTType bit = 0;  
 SELECT @TenantGSTType = GSTType FROM Tenants WHERE TenantId = @TenantID  
  
 BEGIN TRY  
  SELECT @OrderFromDateTime = CAST(@OrderFromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30'   
   ,@OrderToDateTime = CAST(@OrderToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30'   
   ,@InquiryFromDateTime = CAST(@InquiryFromDate AS VARCHAR(10)) + ' 00:00:00.001'   
   ,@InquiryToDateTime = CAST(@InquiryToDate AS VARCHAR(10)) + ' 23:59:59.999'   
   ,@DeliveryFromDateTime = CAST(@DeliveryFromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30'   
   ,@DeliveryToDateTime = CAST(@DeliveryToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30'   
  
  SELECT o.OrderId  
   ,ISNULL(o.LabelId, 0) AS LabelID  
   ,ISNULL(l.LabelName, '') AS LabelName  
   ,ISNULL(l.ColorCode, '') AS ColorCode  
   ,o.OrderNo AS OrderNo  
   --,au.UserId  
   ,au.FirstName + ' ' + au.LastName AS SalesmanName  
   ,c.CustomerId AS CustomerId  
   ,ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,'') AS CustomerName  
   ,c.PhoneNumber AS PhoneNumber  
   ,ROUND(ISNULL(o.AmountBeforeGST, 0), 0) AS ProductAmount  
   ,ROUND(ISNULL(o.CGSTAmount, 0), 0) + ROUND(ISNULL(o.SGSTAmount, 0), 0) AS TaxAmount  
   ,ROUND(ISNULL(o.TotalAmt, 0), 0) AS TotalAmount  
   --,(CASE WHEN @TenantGSTType = 1 THEN ROUND(ISNULL(o.AmountBeforeGST, 0), 0) ELSE ROUND(ISNULL(o.TotalAmt, 0), 0)END) AS TotalAmount  
   ,o.Status AS OrderStatus  
   ,FORMAT(o.CreatedDate,'dd/MM/yyyy') AS InquiryDate  
   ,FORMAT(o.ApprovedDate,'dd/MM/yyyy') AS OrderDate  
   ,FORMAT(o.DeliveryDate, 'dd/MM/yyyy') AS DeliveryDate  
   ,CAST(CASE WHEN sh.OrderId IS NOT NULL THEN 1 ELSE 0 END AS BIT)AS IsStockOnHold  
   ,ISNULL(la.LocationName, '') AS LocationName  
   ,COUNT(1) OVER() AS TotalCount  
  FROM dbo.Orders o WITH (NOLOCK)  
  INNER JOIN dbo.Customers c WITH (NOLOCK) ON c.CustomerId = o.CustomerID  
  INNER JOIN dbo.AspNetUsers au WITH (NOLOCK) ON au.UserId = o.SalesmanId  
  LEFT JOIN dbo.Labels l WITH (NOLOCK) ON l.LabelId = o.LabelId  
   AND l.TenantId = o.TenantId  
  LEFT JOIN(SELECT DISTINCT soh.OrderId  
     FROM StockOnHold soh WITH (NOLOCK)  
     WHERE soh.IsStockOnHold = 1  
     AND DATEADD(DAY, CAST(soh.TimePeriod AS INT), CAST(soh.CreatedDate AS DATETIMEOFFSET)) > SYSDATETIMEOFFSET()  
    ) AS sh ON sh.OrderId = o.OrderId   
  LEFT JOIN dbo.Locations la WITH (NOLOCK) ON la.LocationID = o.LocationID  
   AND la.TenantID = o.TenantId  
   AND la.IsDeleted = 0  
  WHERE o.TenantId = @TenantID  
  AND o.Status <> 9 -- Is Deleted  
  AND (@OrderNo IS NULL OR o.OrderNo LIKE '%' +  @OrderNo + '%')  
  AND (@SalesmanId IS NULL OR o.SalesmanId = @SalesmanId)  
  AND (@CustomerName IS NULL OR (ISNULL(c.FirstName,'') + ' ' + ISNULL(c.LastName,'')) LIKE '%' + @CustomerName + '%')  
  AND (@RefferedBy IS NULL OR o.RefferedBy = @RefferedBy)  
  AND (@PhoneNumber IS NULL OR (c.PhoneNumber LIKE '%' + @PhoneNumber + '%' OR c.AltPhoneNumber LIKE '%' + @PhoneNumber + '%'))  
  AND (@OrderType IS NULL OR o.OrderType = @OrderType)  
  AND (@InquiryFromDate IS NULL OR o.CreatedDate >= @InquiryFromDateTime)  
  AND (@InquiryToDate IS NULL OR o.CreatedDate <= @InquiryToDateTime)  
  AND (@OrderFromDate IS NULL OR o.ApprovedDate >= @OrderFromDateTime)  
  AND (@OrderToDate IS NULL OR o.ApprovedDate <= @OrderToDateTime)  
  AND (@DeliveryFromDate IS NULL OR o.DeliveryDate >= @DeliveryFromDateTime)  
  AND (@DeliveryToDate IS NULL OR o.DeliveryDate <= @DeliveryToDateTime)  
  AND (  
    (@Tags IS NULL)  
    OR (  
     @Tags = 0  
     AND (  
      o.LabelId IS NULL  
      OR o.LabelId = 0  
      )  
     )  
    OR (  
     @Tags <> 0  
     AND @Tags <> - 1  
     AND o.LabelId = @Tags  
     )  
    )  
  AND (@Status IS NULL OR o.Status IN (SELECT value FROM STRING_SPLIT(@Status, ',')))  
  AND (@LocationID IS NULL OR o.LocationID IN (SELECT value FROM STRING_SPLIT(@LocationID, ',')))  
  AND ((@FromPrice IS NULL OR @FromPrice = -1 OR (CASE WHEN @TenantGSTType = 1 THEN ROUND(ISNULL(o.AmountBeforeGST, 0), 0) ELSE ROUND(ISNULL(o.TotalAmt, 0), 0)END) >= @FromPrice))   
  AND ((@ToPrice IS NULL OR @ToPrice = -1 OR (CASE WHEN @TenantGSTType = 1 THEN ROUND(ISNULL(o.AmountBeforeGST, 0), 0) ELSE ROUND(ISNULL(o.TotalAmt, 0), 0)END) <= @ToPrice))  
  AND (@IsStockOnHold IS NULL OR (CAST(CASE WHEN sh.OrderId IS NOT NULL THEN 1 ELSE 0 END AS BIT) = @IsStockOnHold))  
  ORDER BY CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'ASC' THEN O.OrderNo END  
   ,CASE WHEN @SortBy = 'OrderNo' AND @SortOrder = 'DESC' THEN O.OrderNo END DESC  
   ,CASE WHEN @SortBy = 'Salesman' AND @SortOrder = 'ASC' THEN (au.FirstName + ' ' + au.LastName) END  
   ,CASE WHEN @SortBy = 'Salesman' AND @SortOrder = 'DESC' THEN (au.FirstName + ' ' + au.LastName) END DESC  
   ,CASE WHEN @SortBy = 'CustomerName' AND @SortOrder = 'ASC' THEN (c.FirstName + ' ' + c.LastName) END  
   ,CASE WHEN @SortBy = 'CustomerName' AND @SortOrder = 'DESC' THEN (c.FirstName + ' ' + c.LastName) END DESC  
   ,CASE WHEN @SortBy = 'PhoneNumber' AND @SortOrder = 'ASC' THEN ISNULL(c.PhoneNumber, '') END  
   ,CASE WHEN @SortBy = 'PhoneNumber' AND @SortOrder = 'DESC' THEN ISNULL(c.PhoneNumber, '') END DESC  
   ,CASE WHEN @SortBy = 'TotalAmount' AND @SortOrder = 'ASC' THEN o.TotalAmount END  
   ,CASE WHEN @SortBy = 'TotalAmount' AND @SortOrder = 'DESC' THEN o.TotalAmount END DESC  
   ,CASE WHEN @SortBy = 'OrderStatus' AND @SortOrder = 'ASC' THEN o.Status END  
   ,CASE WHEN @SortBy = 'OrderStatus' AND @SortOrder = 'DESC' THEN o.Status END DESC  
   ,CASE WHEN @SortBy = 'InquiryDate' AND @SortOrder = 'ASC' THEN o.CreatedDate END  
   ,CASE WHEN @SortBy = 'InquiryDate' AND @SortOrder = 'DESC' THEN o.CreatedDate END DESC  
   ,CASE WHEN @SortBy = 'OrderDate' AND @SortOrder = 'ASC' THEN o.ApprovedDate END  
   ,CASE WHEN @SortBy = 'OrderDate' AND @SortOrder = 'DESC' THEN o.ApprovedDate END DESC  
   ,CASE WHEN @SortBy = 'DeliveryDate' AND @SortOrder = 'ASC' THEN o.DeliveryDate END  
   ,CASE WHEN @SortBy = 'DeliveryDate' AND @SortOrder = 'DESC' THEN o.DeliveryDate END DESC  
   ,CASE WHEN @SortBy = 'LocationName' AND @SortOrder = 'ASC' THEN la.LocationName END  
   ,CASE WHEN @SortBy = 'LocationName' AND @SortOrder = 'DESC' THEN la.LocationName END DESC  
  OFFSET(@PageIndex - 1) * @PageSize ROWS  
  FETCH NEXT @PageSize ROWS ONLY  
  
 END TRY  
 BEGIN CATCH  
  DECLARE @ErrorMessage NVARCHAR(4000)  
  DECLARE @ErrorSeverity INT  
  DECLARE @ErrorState INT  
  
  SELECT @ErrorMessage = ERROR_MESSAGE()  
  ,@ErrorSeverity = ERROR_SEVERITY()  
  ,@ErrorState = ERROR_STATE()  
  
  RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)  
 END CATCH  
END

GO

