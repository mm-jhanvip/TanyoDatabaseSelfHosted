--select * from [GetRowCount]() ORDER By 2 DESC
CREATE FUNCTION [dbo].[GetRowCount]()
RETURNS TABLE
WITH ENCRYPTION
AS
RETURN
SELECT
    st.Name AS TableName,
    SUM( 
        CASE 
            WHEN (p.index_id < 2) AND (a.type = 1) THEN p.rows 
            ELSE 0 
        END 
       ) AS Rows
     FROM sys.partitions p
     INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
     INNER JOIN sys.tables st ON st.object_id = p.Object_ID
     INNER JOIN sys.schemas sch ON sch.schema_id = st.schema_id
   
     GROUP BY st.name, sch.name

GO

