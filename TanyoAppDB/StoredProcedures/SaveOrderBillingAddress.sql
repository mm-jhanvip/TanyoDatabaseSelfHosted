CREATE PROCEDURE [dbo].[SaveOrderBillingAddress] (
	@OrderId BIGINT
	,@BillingAddressID BIGINT
	,@UserId INT
	)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @OrderAddressId BIGINT
			,@DateOffset DATETIMEOFFSET = SYSDATETIMEOFFSET()
			,@DateUtc DATETIME = GETUTCDATE()
			,@OrderSubjectTypeId INT
			,@TenantId INT
			,@OrderStatus INT

		SELECT @TenantId = o.TenantId
			,@OrderStatus = o.STATUS
		FROM Orders o WITH (NOLOCK)
		WHERE o.OrderId = @OrderId

		SELECT @OrderSubjectTypeId = st.SubjectTypeId
		FROM SubjectTypes st WITH (NOLOCK)
		WHERE st.TenantId = @TenantId
			AND st.SubjectTypeName = 'Orders'

		-- Check if Billing address already exists for this order
		SELECT @OrderAddressId = oa.OrderAddressId
		FROM dbo.OrderAddresses oa WITH (NOLOCK)
		WHERE oa.OrderId = @OrderId
			AND oa.AddressType = 'Billing'

		-- Insert if not exists
		IF @OrderAddressId IS NULL
		BEGIN
			INSERT INTO dbo.OrderAddresses (
				OrderId
				,CustomerAddressId
				,FirstName
				,LastName
				,EmailId
				,PhoneNumber
				,AddressType
				,Street1
				,Street2
				,Landmark
				,Area
				,City
				,STATE
				,ZipCode
				,CreatedBy
				,CreatedDate
				,CreatedUTCDate
				,GSTNo
				,CompanyName
				,Latitude
				,Longitude
				,Country
				,FullAddress
				)
			SELECT @OrderId
				,ca.CustomerAddressId
				,c.FirstName
				,ISNULL(c.LastName, '')
				,c.EmailId
				,c.PhoneNumber
				,'Billing'
				,ca.Street1
				,ca.Street2
				,ca.Landmark
				,ca.Area
				,ca.City
				,ca.STATE
				,ca.ZipCode
				,@UserID
				,@DateOffset
				,@DateUtc
				,COALESCE(
					NULLIF(LTRIM(RTRIM(ca.GSTNo)), '')
					,NULLIF(LTRIM(RTRIM(def_ca.GSTNo)), '')
					,NULLIF(LTRIM(RTRIM(c.GSTNo)), '')
				)
				,ca.CompanyName
				,ca.Latitude
				,ca.Longitude
				,ca.Country
				,ca.FullAddress
			FROM dbo.CustomerAddresses ca WITH (NOLOCK)
			INNER JOIN dbo.Customers c WITH (NOLOCK) ON c.CustomerId = ca.CustomerId
			LEFT JOIN dbo.CustomerAddresses def_ca WITH (NOLOCK)
				ON def_ca.CustomerId = c.CustomerId
				AND def_ca.IsDefault = 1
				AND def_ca.IsDeleted = 0
			WHERE ca.CustomerAddressId = @BillingAddressID
				AND ca.IsDeleted = 0

			SELECT CAST(1 AS BIT) AS [Status]
				,'Billing address inserted successfully.' AS [Message]
		END
		ELSE
		BEGIN
			-- Update if exists
			UPDATE oa
			SET oa.CustomerAddressId = ca.CustomerAddressId
				,oa.FirstName = c.FirstName
				,oa.LastName = ISNULL(c.LastName, '')
				,oa.EmailId = c.EmailId
				,oa.PhoneNumber = c.PhoneNumber
				,oa.Street1 = ca.Street1
				,oa.Street2 = ca.Street2
				,oa.Landmark = ca.Landmark
				,oa.Area = ca.Area
				,oa.City = ca.City
				,oa.STATE = ca.STATE
				,oa.ZipCode = ca.ZipCode
				,oa.UpdatedBy = @UserID
				,oa.UpdatedDate = @DateOffset
				,oa.UpdatedUTCDate = @DateUtc
				,oa.GSTNo = COALESCE(
					NULLIF(LTRIM(RTRIM(ca.GSTNo)), '')
					,NULLIF(LTRIM(RTRIM(def_ca.GSTNo)), '')
					,NULLIF(LTRIM(RTRIM(c.GSTNo)), '')
				)
				,oa.CompanyName = ca.CompanyName
				,oa.Country = ca.Country
				,oa.Latitude = ca.Latitude
				,oa.Longitude = ca.Longitude
				,oa.FullAddress = ca.FullAddress
			FROM dbo.OrderAddresses oa
			INNER JOIN dbo.CustomerAddresses ca WITH (NOLOCK) ON ca.CustomerAddressId = @BillingAddressID
			INNER JOIN dbo.Customers c WITH (NOLOCK) ON c.CustomerId = ca.CustomerId
			LEFT JOIN dbo.CustomerAddresses def_ca WITH (NOLOCK)
				ON def_ca.CustomerId = c.CustomerId
				AND def_ca.IsDefault = 1
				AND def_ca.IsDeleted = 0
			WHERE oa.OrderAddressId = @OrderAddressId

			SELECT CAST(1 AS BIT) AS [Status]
				,'Billing address updated successfully.' AS [Message]
		END

		IF @OrderStatus IN (2,3)
		BEGIN
			EXEC dbo.SaveActivityLog
			     @SubjectTypeId = @OrderSubjectTypeId
				,@SubjectId = @OrderId
				,@Description = 'Billing address has been changed.'
				,@Action = 'UPDATE'
				,@CreatedBy = @UserId
				,@CreatedDate = @DateOffset
				,@CreatedUTCDate = @DateUtc;
		END
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		SET @ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage;

		SELECT CAST(0 AS BIT) AS [Status]
			,@ErrorMessage AS [Message]

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

