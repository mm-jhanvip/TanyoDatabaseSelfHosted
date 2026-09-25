/*
 EXEC DeleteTenant UserData
  @TenantId = 00000000000000000000000
  ,@Type = 1
*/
CREATE PROC [dbo].[DeleteTenant]
(
 @TenantId BIGINT
 ,@Type INT--2: Delete all, 1: Delete Products,0: delete Masters
)
WITH ENCRYPTION
AS
BEGIN
	-- OTP / Auth Cleanup
	DELETE FROM OTPLogin WHERE PhoneNumber IN (SELECT PhoneNumber FROM Customers WHERE TenantId = @TenantId UNION ALL SELECT PhoneNumber FROM AspNetUsers INNER JOIN UserTenantMapping ON AspNetUsers.UserId = UserTenantMapping.UserId WHERE UserTenantMapping.TenantId = @TenantId)

	-- Activity Logs
	DELETE FROM ActivityLogs WHERE SubjectTypeId IN (SELECT SubjectTypeId FROM SubjectTypes WHERE TenantId = @TenantId)

	-- Complains
	DELETE FROM ComplainAttachments WHERE ComplainId IN (SELECT ComplainId FROM Complains WHERE TenantId = @TenantId)
	DELETE FROM ComplainComments WHERE ComplainId IN (SELECT ComplainId FROM Complains WHERE TenantId = @TenantId)
	DELETE FROM Complains WHERE TenantId = @TenantId

	-- Customers
	DELETE FROM CustomerAddresses WHERE CustomerId IN (SELECT CustomerId FROM Customers WHERE TenantId = @TenantId)
	DELETE FROM CustomerVisits WHERE CustomerId IN (SELECT CustomerId FROM Customers WHERE TenantId = @TenantId)
	DELETE FROM Customers WHERE TenantId = @TenantId

	-- Inquiries
	DELETE FROM InquiryComments WHERE InquiryId IN (SELECT InquiryId FROM Inquiries WHERE TenantId = @TenantId)
	DELETE FROM InquiryLogs WHERE InquiryId IN (SELECT InquiryId FROM Inquiries WHERE TenantId = @TenantId)
	DELETE FROM Inquiries WHERE TenantId = @TenantId
	DELETE FROM BackInquiries WHERE TenantID = @TenantId

	-- Manufacturing Workflows
	DELETE FROM ManufacturingActivityLogs WHERE ManufacturingWorkflowId IN (SELECT ManufacturingWorkflowId FROM ManufacturingWorkflows WHERE TenantId = @TenantId)
	DELETE FROM ManufacturingWorkflowMapping WHERE ManufacturingWorkflowId IN (SELECT ManufacturingWorkflowId FROM ManufacturingWorkflows WHERE TenantId = @TenantId)
	DELETE FROM ManufacturingWorkflows WHERE TenantId = @TenantId

	-- Notifications
	DELETE FROM NotificationManagement WHERE TenantId = @TenantId
	DELETE FROM Notifications WHERE TenantId = @TenantId
	DELETE FROM NotificationTemplate WHERE TenantId = @TenantId

	-- Orders
	DELETE FROM Payments WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM PaymentRazorPay WHERE TenantId = @TenantId
	DELETE FROM OrderAddresses WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderAnonymousViews WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderAttachments WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderComments WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderManufacturingWorkflows WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderManufacturingWorkflowImages WHERE OrderManufacturingWorkflowId IN (SELECT OrderManufacturingWorkflowId FROM OrderManufacturingWorkflows WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId))
	DELETE FROM OrderProductCharges WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderSetItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderSetItemImages WHERE OrderSetItemId IN (SELECT OrderSetItemId FROM OrderSetItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId))
	DELETE FROM OrderSetItemReceivables WHERE OrderSetItemId IN (SELECT OrderSetItemId FROM OrderSetItems WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId))
	DELETE FROM OrderSets WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM OrderShortedURL WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM WhatsAppComplaintLogs WHERE OrderId IN (SELECT OrderId FROM Orders WHERE TenantId = @TenantId)
	DELETE FROM Orders_Trigger_Log WHERE TenantId = @TenantId
	DELETE FROM FeedbackOrders WHERE TenantId = @TenantId
	DELETE FROM OrderStatus WHERE TenantId = @TenantId
	DELETE FROM RecurringPaymentRecords WHERE TenantId = @TenantId
	DELETE FROM TenantRecordPayment WHERE TenantId = @TenantId
	DELETE FROM Orders WHERE TenantId = @TenantId
	DELETE FROM Archive_Orders20260128 WHERE TenantId = @TenantId

	-- Purchase Orders
	DELETE FROM POProductPayment WHERE TenantId = @TenantId
	DELETE FROM POProducts WHERE TenantId = @TenantId
	DELETE FROM PORawMaterials WHERE TenantId = @TenantId

	-- Stock / Inward
	DELETE FROM StockTransferLog WHERE TenantId = @TenantId
	DELETE FROM StockTransfer WHERE TenantId = @TenantId
	DELETE FROM InwardEntry WHERE TenantId = @TenantId
	DELETE FROM RawMaterialInwardEntry WHERE TenantId = @TenantId

	-- Wrk Import
	DELETE FROM WrkImportCustomers WHERE WrkImportFileID IN (SELECT WrkImportFileID FROM WrkImportFiles WHERE TenantId = @TenantId)
	DELETE FROM WrkImportFabrics WHERE WrkImportFileID IN (SELECT WrkImportFileID FROM WrkImportFiles WHERE TenantId = @TenantId)
	DELETE FROM WrkImportFiles WHERE TenantId = @TenantId

	-- Leads
	DELETE FROM LeadComments WHERE LeadId IN (SELECT LeadId FROM Leads WHERE TenantId = @TenantId)
	DELETE FROM LeadAudios WHERE LeadId IN (SELECT LeadId FROM Leads WHERE TenantId = @TenantId)
	DELETE FROM LeadLogs WHERE LeadId IN (SELECT LeadId FROM Leads WHERE TenantId = @TenantId)
	DELETE FROM Leads WHERE TenantId = @TenantId
	DELETE FROM WrkLead WHERE TenantId = @TenantId

	-- Feedback / Offers
	DELETE FROM FeedbackQuestions WHERE TenantId = @TenantId
	DELETE FROM Offers WHERE TenantId = @TenantId

	-- Catalogue & Vendors
	DELETE FROM Catalogue WHERE TenantId = @TenantId
	DELETE FROM VendorAddresses WHERE VendorId IN (SELECT VendorId FROM Vendors WHERE TenantId = @TenantId)
	DELETE FROM Vendors WHERE TenantId = @TenantId

	-- Announcements
	DELETE FROM AnnouncementsUserMapping WHERE TenantId = @TenantId
	DELETE FROM Announcements WHERE TenantId = @TenantId

	-- WhatsApp Templates
	DELETE FROM WhatsAppTemplateMappings WHERE TenantId = @TenantId
	DELETE FROM WhatsAppTemplates WHERE TenantId = @TenantId

	-- Facebook / Social
	DELETE FROM FacebookAPIPageDetails WHERE TenantId = @TenantId
	DELETE FROM FacebookLoginCredentials WHERE TenantId = @TenantId

	-- Sales / Analytics
	DELETE FROM SalesAnalysis WHERE TenantID = @TenantId
	--DELETE FROM CombinedSalesAnalysis WHERE TenantId = @TenantId

	-- Misc / Logging
	DELETE FROM DeviceLogs WHERE TenantID = @TenantId
	DELETE FROM ErrorLogs WHERE TenantId = @TenantId
	DELETE FROM KafkaEmailSending WHERE TenantID = @TenantId
	DELETE FROM Tasks WHERE TenantId = @TenantId
	DELETE FROM TagType WHERE TenantId = @TenantId
	DELETE FROM Warehouse WHERE TenantId = @TenantId
	DELETE FROM Frames WHERE TenantId = @TenantId
	DELETE FROM Accessories WHERE TenantId = @TenantId
	DELETE FROM AccessoriesTypes WHERE TenantId = @TenantId

	IF @Type = 1 --Clean Products and Categories Data
	BEGIN
		DELETE FROM ManufacturingCategories WHERE TenantId = @TenantId
		DELETE FROM Categories WHERE TenantId = @TenantId
		DELETE FROM Companies WHERE TenantId = @TenantId
		DELETE FROM Fabrics WHERE TenantId = @TenantId
		DELETE FROM Polish WHERE TenantId = @TenantId
		DELETE FROM Labours WHERE TenantId = @TenantId
		DELETE FROM RawMaterials WHERE TenantId = @TenantId
		DELETE FROM PriceChangeLogs WHERE EntityID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductImages WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		--DELETE FROM ProductLabours WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductMaterials WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductQuantities WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductWorkflows WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductCustomFields WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductOffers WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductSets WHERE TenantId = @TenantId
		DELETE FROM ProductShareBatchDetail WHERE TenantId = @TenantId
		DELETE FROM ProductShareBatch WHERE TenantId = @TenantId
		DELETE FROM Products WHERE TenantId = @TenantId
	END

	IF @Type = 0 --Clean Master Data
	BEGIN
		DELETE FROM AspNetRoleClaims WHERE RoleId IN (SELECT Id FROM AspNetRoles WHERE TenantId = @TenantId)
		DELETE FROM AspNetRoles WHERE TenantId = @TenantId
		DELETE FROM AspNetUserRoles WHERE UserId IN (SELECT Id FROM AspNetUsers WHERE UserId IN (SELECT UserId FROM UserTenantMapping WHERE TenantId = @TenantId))
		DELETE FROM AspNetUsers WHERE UserId IN (SELECT UserId FROM UserTenantMapping WHERE TenantId = @TenantId)
		DELETE FROM UserTenantMapping WHERE TenantId = @TenantId
		--DELETE FROM UserData WHERE TenantId = @TenantId
		DELETE FROM EmailCMSDetails WHERE EmailCMSID IN (SELECT EmailCMSID FROM EmailCMS WHERE TenantId = @TenantId)
		DELETE FROM EmailCMS WHERE TenantId = @TenantId
		DELETE FROM Labels WHERE TenantId = @TenantId
		DELETE FROM LookupValues WHERE LookupId IN (SELECT LookupId FROM Lookups WHERE TenantId = @TenantId)
		DELETE FROM Lookups WHERE TenantId = @TenantId
		DELETE FROM SubjectTypes WHERE TenantId = @TenantId
		DELETE FROM Departments WHERE TenantId = @TenantId
		DELETE FROM Designations WHERE TenantId = @TenantId
		DELETE FROM Holidays WHERE TenantId = @TenantId
		DELETE FROM LeaveCategory WHERE TenantId = @TenantId
		DELETE FROM Locations WHERE TenantID = @TenantId
		DELETE FROM Contractor WHERE TenantId = @TenantId
		DELETE FROM OrganizationOwnerDetails WHERE TenantId = @TenantId
		DELETE FROM OrganizationTimings WHERE TenantId = @TenantId
		DELETE FROM TenantBankDetails WHERE TenantId = @TenantId
		DELETE FROM TenantReminderSettings WHERE TenantId = @TenantId
		DELETE FROM TenantSMTPDetails WHERE TenantId = @TenantId
		DELETE FROM TenantWhatsAppDetails WHERE TenantId = @TenantId
		DELETE FROM TenantConfigurations WHERE TenantId = @TenantId
		DELETE FROM TenantContracts WHERE TenantID = @TenantId
		DELETE FROM TenantInvoiceFormatMapping WHERE TenantId = @TenantId
		DELETE FROM TenantIPDomainRequestLog WHERE TenantId = @TenantId
		DELETE FROM TenantIPDomainWhitelist WHERE TenantId = @TenantId
		DELETE FROM TenantModulePermissions WHERE TenantId = @TenantId
		DELETE FROM TenantAPICount WHERE TenantId = @TenantId
		DELETE FROM TenantUsageStatistics WHERE TenantId = @TenantId
		DELETE FROM AzureBlobStorageSize WHERE TenantID = @TenantId
		DELETE FROM TallyConfiguration WHERE TenantId = @TenantId
		DELETE FROM Tenants WHERE TenantId = @TenantId
	END

	IF @Type = 2 --Delete All
	BEGIN
		DELETE FROM ManufacturingCategories WHERE TenantId = @TenantId
		DELETE FROM Categories WHERE TenantId = @TenantId
		DELETE FROM Companies WHERE TenantId = @TenantId
		DELETE FROM Fabrics WHERE TenantId = @TenantId
		DELETE FROM Polish WHERE TenantId = @TenantId
		DELETE FROM Labours WHERE TenantId = @TenantId
		DELETE FROM RawMaterials WHERE TenantId = @TenantId
		DELETE FROM PriceChangeLogs WHERE EntityID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductImages WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		--DELETE FROM ProductLabours WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductMaterials WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductQuantities WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductWorkflows WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductCustomFields WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductOffers WHERE ProductID IN (SELECT ProductId FROM Products WHERE TenantId = @TenantId)
		DELETE FROM ProductSets WHERE TenantId = @TenantId
		DELETE FROM ProductShareBatchDetail WHERE TenantId = @TenantId
		DELETE FROM ProductShareBatch WHERE TenantId = @TenantId
		DELETE FROM Products WHERE TenantId = @TenantId

		DELETE FROM AspNetRoleClaims WHERE RoleId IN (SELECT Id FROM AspNetRoles WHERE TenantId = @TenantId)
		DELETE FROM AspNetRoles WHERE TenantId = @TenantId
		DELETE FROM AspNetUserRoles WHERE UserId IN (SELECT Id FROM AspNetUsers WHERE UserId IN (SELECT UserId FROM UserTenantMapping WHERE TenantId = @TenantId))
		DELETE FROM AspNetUsers WHERE UserId IN (SELECT UserId FROM UserTenantMapping WHERE TenantId = @TenantId)
		DELETE FROM UserTenantMapping WHERE TenantId = @TenantId
		--DELETE FROM UserData WHERE TenantId = @TenantId
		DELETE FROM EmailCMSDetails WHERE EmailCMSID IN (SELECT EmailCMSID FROM EmailCMS WHERE TenantId = @TenantId)
		DELETE FROM EmailCMS WHERE TenantId = @TenantId
		DELETE FROM Labels WHERE TenantId = @TenantId
		DELETE FROM LookupValues WHERE LookupId IN (SELECT LookupId FROM Lookups WHERE TenantId = @TenantId)
		DELETE FROM Lookups WHERE TenantId = @TenantId
		DELETE FROM SubjectTypes WHERE TenantId = @TenantId
		DELETE FROM Departments WHERE TenantId = @TenantId
		DELETE FROM Designations WHERE TenantId = @TenantId
		DELETE FROM Holidays WHERE TenantId = @TenantId
		DELETE FROM LeaveCategory WHERE TenantId = @TenantId
		DELETE FROM Locations WHERE TenantID = @TenantId
		DELETE FROM Contractor WHERE TenantId = @TenantId
		DELETE FROM OrganizationOwnerDetails WHERE TenantId = @TenantId
		DELETE FROM OrganizationTimings WHERE TenantId = @TenantId
		DELETE FROM TenantBankDetails WHERE TenantId = @TenantId
		DELETE FROM TenantReminderSettings WHERE TenantId = @TenantId
		DELETE FROM TenantSMTPDetails WHERE TenantId = @TenantId
		DELETE FROM TenantWhatsAppDetails WHERE TenantId = @TenantId
		DELETE FROM TenantConfigurations WHERE TenantId = @TenantId
		DELETE FROM TenantContracts WHERE TenantID = @TenantId
		DELETE FROM TenantInvoiceFormatMapping WHERE TenantId = @TenantId
		DELETE FROM TenantIPDomainRequestLog WHERE TenantId = @TenantId
		DELETE FROM TenantIPDomainWhitelist WHERE TenantId = @TenantId
		DELETE FROM TenantModulePermissions WHERE TenantId = @TenantId
		DELETE FROM TenantAPICount WHERE TenantId = @TenantId
		DELETE FROM TenantUsageStatistics WHERE TenantId = @TenantId
		DELETE FROM AzureBlobStorageSize WHERE TenantID = @TenantId
		DELETE FROM TallyConfiguration WHERE TenantId = @TenantId
		DELETE FROM Tenants WHERE TenantId = @TenantId
	END
END

GO

