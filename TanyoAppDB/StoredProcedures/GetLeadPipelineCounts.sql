/*  
  EXEC [dbo].[GetLeadPipelineCounts] @TenantId = 192  
*/  
CREATE PROCEDURE [dbo].[GetLeadPipelineCounts]  
(  
   @TenantId INT  
)  
WITH ENCRYPTION
AS
BEGIN  
    SET NOCOUNT ON;  
  
    BEGIN TRY  
        SELECT  
            COUNT(CASE WHEN ISNULL(l.LeadType, 0) = 0 AND u.FieldStoreOperationType = 1 THEN 1 END) AS FieldPipelineCount,  
            COUNT(CASE WHEN ISNULL(l.LeadType, 0) = 0 AND u.FieldStoreOperationType IN (2, 3) THEN 1 END) AS SalesPipelineCount,  
            COUNT(CASE WHEN ISNULL(l.LeadType, 0) = 1 AND u.FieldStoreOperationType IN (2, 3) THEN 1 END) AS ArchitectsVisitStoreCount,  
            COUNT(CASE WHEN ISNULL(l.LeadType, 0) = 1 AND u.FieldStoreOperationType = 1 THEN 1 END) AS ArchitectsVisitFieldCount  
        FROM dbo.Leads l WITH (NOLOCK)  
        INNER JOIN dbo.AspNetUsers u WITH (NOLOCK) ON l.SalesmanId = u.UserId  
        WHERE l.TenantId = @TenantId  
          AND l.Status <> 6;  
    END TRY  
    BEGIN CATCH  
        DECLARE @ObjectName VARCHAR(500),  
                @ErrorMsg VARCHAR(MAX);  
  
        SET @ObjectName = OBJECT_NAME(@@PROCID);  
        SET @ErrorMsg = ERROR_MESSAGE();  
  
        EXEC dbo.SaveDBErrorLog   
            @ObjectName = @ObjectName,  
            @ErrorMsg = @ErrorMsg;  
    END CATCH  
END

GO

