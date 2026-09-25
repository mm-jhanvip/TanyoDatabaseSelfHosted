/*
 EXEC [dbo].[LookupCustomerWithReferral]
  @Search = '98',
  @TenantId = 1207
*/
CREATE   PROCEDURE [dbo].[LookupCustomerWithReferral]
(
    @Search VARCHAR(200),
    @TenantId INT
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            c.CustomerId,
            RTRIM(LTRIM(c.FirstName + ' ' + ISNULL(c.LastName, ''))) AS FullName,
            c.PhoneNumber,
            c.EmailId,
            c.CustomerTypeId,
            c.RefferedBy,
            ref.CustomerId            AS RefferedCustomerId,
            RTRIM(LTRIM(ref.FirstName + ' ' + ISNULL(ref.LastName, ''))) AS RefferedFullName,
            ref.PhoneNumber           AS RefferedPhoneNumber,
            ref.EmailId               AS RefferedEmailId,
            ref.CustomerTypeId        AS RefferedCustomerTypeId,
            ref.InteriorCommissionPer AS RefferedInteriorCommissionPer
        FROM [dbo].[Customers] c WITH (NOLOCK)
        LEFT JOIN [dbo].[Customers] ref WITH (NOLOCK)
            ON c.RefferedBy = ref.CustomerId AND ref.IsDeleted = 0
        WHERE c.IsDeleted = 0
          AND c.TenantId = @TenantId
          AND c.CustomerTypeId IN (1, 2)
          AND (
              c.PhoneNumber LIKE @Search + '%'
              OR c.AltPhoneNumber LIKE @Search + '%'
              OR (c.FirstName + ' ' + ISNULL(c.LastName, '')) LIKE '%' + @Search + '%'
          )
        ORDER BY FullName;

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

