-- =============================================  
-- Author:  Meet Dobariya  
-- Create date: 02-05-2023  
-- Description: Generate ComplainKey  
-- =============================================  
--SELECT dbo.GetComplainKey('R')  
CREATE FUNCTION [dbo].[GetComplainKey]  
(  
 @Type VARCHAR(1)    
)  
RETURNS VARCHAR(15)  
WITH ENCRYPTION
AS
BEGIN  
 DECLARE @ComplainKey VARCHAR(15)  
  
 SELECT @ComplainKey = FORMAT(GETDATE(), 'ddMMyyyy')  
  
 DECLARE @Random VARCHAR(5), @inc INT, @sum INT  
  
 SELECT @Random = LEFT(ABS(CHECKSUM(RandomID)), 5)  
 FROM GetRandomID  
  
 SELECT @inc = 0  
  ,@sum = 0  
  
 WHILE @inc <= LEN(@Random)  
 BEGIN  
  SET @sum = @sum + CAST(SUBSTRING(@Random, @inc, 1) AS INT)  
  SET @inc = @inc + 1  
 END  
  
 SELECT @ComplainKey = @Type + @Random + '-' + @ComplainKey  
  
 IF EXISTS (  
    SELECT ComplainKey  
    FROM Complains c WITH (NOLOCK)  
    WHERE c.ComplainKey = @ComplainKey  
   )  
 BEGIN  
  SELECT @ComplainKey = dbo.GetComplainKey(@Type)  
 END  
  
 RETURN @ComplainKey  
END

GO

