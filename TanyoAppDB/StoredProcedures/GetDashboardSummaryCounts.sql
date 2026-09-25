-- =============================================
-- Author       : MagnusMinds
-- Create date  : 14-09-2026
-- Updated date : 15-09-2026
-- Description  : Get Dashboard Summary Counts with Direct DB Role Claims & Permissions (Fully Optimized)
-- =============================================
/*
    EXEC [dbo].[GetDashboardSummaryCounts]
        @TenantId = 1207,
        @LocationId = -1,
        @UserId = 13307;
*/
CREATE PROCEDURE [dbo].[GetDashboardSummaryCounts] 
	 @TenantId INT
	,@LocationId BIGINT = NULL
	,@UserId BIGINT 
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		-- =========================================================
		-- 1. Initialize count variables (Default: 0)
		-- =========================================================
		DECLARE
			-- CRM
			@CustomerCount INT = 0
			,@InteriorCount INT = 0
			,@ProductCount INT = 0
			,@OfferedProductCount INT = 0
			,
			-- Retailer Orders
			@Inquiries INT = 0
			,@PendingOrders INT = 0
			,@ApprovedOrders INT = 0
			,@InprogressOrders INT = 0
			,@DeliveredRetailerOrders INT = 0
			,@ArchiveOrders INT = 0
			,@OnHoldOrders INT = 0
			,@Receivables INT = 0
			,
			-- Wholesaler Orders
			@InquiriesWholesalerOrder INT = 0
			,@PendingWholesalerOrders INT = 0
			,@ApprovedWholesalerOrders INT = 0
			,@InProgressWholesalerOrders INT = 0
			,@DeliveredWholesalerOrders INT = 0
			,@ArchiveWholesalerOrders INT = 0
			,@OnHoldWholesalerOrders INT = 0
			,@ReceivablesWholesalerCount INT = 0
			,
			-- Complaints
			@OpenComplain INT = 0
			,@InprogressComplain INT = 0
			,@CloseComplain INT = 0
			,
			-- Leads
			@PendingInquiry INT = 0
			,@InProgressInquiry INT = 0
			,@CompletedInquiry INT = 0
			,@NurtureInquiry INT = 0
			,@DisqualifiedInquiry INT = 0
			,@ClosedInquiry INT = 0
			,@UnassignedInquiry INT = 0
			,
			-- Manufacturing
			@ReadyToManufacturerCount INT = 0
			,@ManufacturingOrderCount INT = 0
			,@ReadyToDeliveryCount INT = 0
			,@DeliveredCount INT = 0;
		-- =========================================================
		-- 2. Resolve Role Claims & Permissions (Single Pass)
		-- =========================================================
		DECLARE @HasCrmSection BIT = 0
			,@HasRetailerSection BIT = 0
			,@HasWholesalerSection BIT = 0
			,@HasComplainSection BIT = 0
			,@HasLeadSection BIT = 0
			,@HasCustomerCount BIT = 0
			,@HasInteriorCount BIT = 0
			,@HasProductCount BIT = 0
			,@HasOfferedProductCount BIT = 0
			,@HasInquiries BIT = 0
			,@HasPendingOrders BIT = 0
			,@HasApprovedOrders BIT = 0
			,@HasInprogressOrders BIT = 0
			,@HasOnHoldOrders BIT = 0
			,@HasArchiveOrders BIT = 0
			,@HasDeliveredRetailerOrders BIT = 0
			,@HasReceivables BIT = 0
			,@HasInquiriesWholesalerOrder BIT = 0
			,@HasPendingWholesalerOrders BIT = 0
			,@HasApprovedWholesalerOrders BIT = 0
			,@HasInProgressWholesalerOrders BIT = 0
			,@HasOnHoldWholesalerOrders BIT = 0
			,@HasArchiveWholesalerOrders BIT = 0
			,@HasDeliveredWholesalerOrders BIT = 0
			,@HasReceivablesWholesalerCount BIT = 0
			,@HasOpenComplain BIT = 0
			,@HasInprogressComplain BIT = 0
			,@HasCloseComplain BIT = 0
			,@HasPendingInquiry BIT = 0
			,@HasInProgressInquiry BIT = 0
			,@HasCompletedInquiry BIT = 0
			,@HasNurtureInquiry BIT = 0
			,@HasDisqualifiedInquiry BIT = 0
			,@HasClosedInquiry BIT = 0
			,@HasUnassignedInquiry BIT = 0
			,@HasReadyToManufacturerCount BIT = 0
			,@HasManufacturingOrderCount BIT = 0
			,@HasReadyToDeliveryCount BIT = 0
			,@HasFactoryDelivered BIT = 0;

		-- 2.1 Fetch all raw claims in one single pass directly to variables
		SELECT
			-- Section Claims
			@HasCrmSection = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.DashboardSections.CRM'
							THEN 1
						ELSE 0
						END), 0)
			,@HasRetailerSection = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.DashboardSections.RetailerOrders'
							THEN 1
						ELSE 0
						END), 0)
			,@HasWholesalerSection = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.DashboardSections.WholesalerOrders'
							THEN 1
						ELSE 0
						END), 0)
			,@HasComplainSection = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.DashboardSections.Complaints'
							THEN 1
						ELSE 0
						END), 0)
			,@HasLeadSection = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.DashboardSections.Leads'
							THEN 1
						ELSE 0
						END), 0)
			,
			-- CRM Claims
			@HasCustomerCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.CustomersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasInteriorCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InteriorsView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasProductCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ProductsView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasOfferedProductCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ProductsView'
							THEN 1
						ELSE 0
						END), 0)
			,
			-- Retailer Claims
			@HasInquiries = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InquiriesView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasPendingOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.PendingOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasApprovedOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ApprovedOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasInprogressOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InProgressOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasOnHoldOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.OnHoldView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasArchiveOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.OnArchiveView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasDeliveredRetailerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.Delivered'
							THEN 1
						ELSE 0
						END), 0)
			,@HasReceivables = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ReceivablesView'
							THEN 1
						ELSE 0
						END), 0)
			,
			-- Wholesaler Claims
			@HasInquiriesWholesalerOrder = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InquiriesView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasPendingWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.PendingOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasApprovedWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ApprovedOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasInProgressWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InProgressOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasOnHoldWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.OnHoldView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasArchiveWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.OnArchiveView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasDeliveredWholesalerOrders = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.Delivered'
							THEN 1
						ELSE 0
						END), 0)
			,@HasReceivablesWholesalerCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue IN (
								'Permissions.Portal.Dashboard.ReceivablesView'
								,'Permissions.Portal.Dashboard.ReadyToManufacturer'
								)
							THEN 1
						ELSE 0
						END), 0)
			,
			-- Complaints Claims
			@HasOpenComplain = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.OpenComplainView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasInprogressComplain = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.InprogressComplainView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasCloseComplain = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.CloseComplainView'
							THEN 1
						ELSE 0
						END), 0)
			,
			-- Leads Claims
			@HasUnassignedInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.UnassignedLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasPendingInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.AssignedLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasInProgressInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.WorkingLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasCompletedInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.QualifiedLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasNurtureInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.NurtureLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasDisqualifiedInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.DisqualifiedLead'
							THEN 1
						ELSE 0
						END), 0)
			,@HasClosedInquiry = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ClosedLead'
							THEN 1
						ELSE 0
						END), 0)
			,
			-- Manufacturing Claims
			@HasReadyToManufacturerCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ReadyToManufacturer'
							THEN 1
						ELSE 0
						END), 0)
			,@HasManufacturingOrderCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ManufacturingOrdersView'
							THEN 1
						ELSE 0
						END), 0)
			,@HasReadyToDeliveryCount = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.ReadyToDeliver'
							THEN 1
						ELSE 0
						END), 0)
			,@HasFactoryDelivered = ISNULL(MAX(CASE 
						WHEN rc.ClaimValue = 'Permissions.Portal.Dashboard.FactoryDelivered'
							THEN 1
						ELSE 0
						END), 0)
		FROM dbo.AspNetUsers u WITH (NOLOCK)
		INNER JOIN dbo.AspNetUserRoles ur WITH (NOLOCK) ON u.Id = ur.UserId
		INNER JOIN dbo.AspNetRoleClaims rc WITH (NOLOCK) ON ur.RoleId = rc.RoleId
		WHERE u.UserId = @UserId
			AND rc.ClaimValue IS NOT NULL;

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.TenantModulePermissions WITH (NOLOCK)
				WHERE TenantId = @TenantId
					AND ClaimValue = 'Permissions.Complain'
				)
			SET @HasComplainSection = 0;

		IF NOT EXISTS (
				SELECT 1
				FROM dbo.TenantModulePermissions WITH (NOLOCK)
				WHERE TenantId = @TenantId
					AND ClaimValue = 'Permissions.Leads'
				)
			SET @HasLeadSection = 0;

		-- 2.3 Apply Section Constraints (Zero out items if parent section is disabled)
		IF (@HasCrmSection = 0)
		BEGIN
			SET @HasCustomerCount = 0;
			SET @HasInteriorCount = 0;
			SET @HasProductCount = 0;
			SET @HasOfferedProductCount = 0;
		END

		IF (@HasRetailerSection = 0)
		BEGIN
			SET @HasInquiries = 0;
			SET @HasPendingOrders = 0;
			SET @HasApprovedOrders = 0;
			SET @HasInprogressOrders = 0;
			SET @HasOnHoldOrders = 0;
			SET @HasArchiveOrders = 0;
			SET @HasDeliveredRetailerOrders = 0;
			SET @HasReceivables = 0;
		END

		IF (@HasWholesalerSection = 0)
		BEGIN
			SET @HasInquiriesWholesalerOrder = 0;
			SET @HasPendingWholesalerOrders = 0;
			SET @HasApprovedWholesalerOrders = 0;
			SET @HasInProgressWholesalerOrders = 0;
			SET @HasOnHoldWholesalerOrders = 0;
			SET @HasArchiveWholesalerOrders = 0;
			SET @HasDeliveredWholesalerOrders = 0;
			SET @HasReceivablesWholesalerCount = 0;
		END

		IF (@HasComplainSection = 0)
		BEGIN
			SET @HasOpenComplain = 0;
			SET @HasInprogressComplain = 0;
			SET @HasCloseComplain = 0;
		END

		IF (@HasLeadSection = 0)
		BEGIN
			SET @HasUnassignedInquiry = 0;
			SET @HasPendingInquiry = 0;
			SET @HasInProgressInquiry = 0;
			SET @HasCompletedInquiry = 0;
			SET @HasNurtureInquiry = 0;
			SET @HasDisqualifiedInquiry = 0;
			SET @HasClosedInquiry = 0;
		END

		-- =========================================================
		-- 3. Structured IF/ELSE Block (Early Exit Evaluation)
		-- =========================================================
		IF (
				@HasCustomerCount = 0
				AND @HasInteriorCount = 0
				AND @HasProductCount = 0
				AND @HasOfferedProductCount = 0
				AND @HasInquiries = 0
				AND @HasPendingOrders = 0
				AND @HasApprovedOrders = 0
				AND @HasInprogressOrders = 0
				AND @HasDeliveredRetailerOrders = 0
				AND @HasArchiveOrders = 0
				AND @HasOnHoldOrders = 0
				AND @HasReceivables = 0
				AND @HasInquiriesWholesalerOrder = 0
				AND @HasPendingWholesalerOrders = 0
				AND @HasApprovedWholesalerOrders = 0
				AND @HasInProgressWholesalerOrders = 0
				AND @HasDeliveredWholesalerOrders = 0
				AND @HasArchiveWholesalerOrders = 0
				AND @HasOnHoldWholesalerOrders = 0
				AND @HasReceivablesWholesalerCount = 0
				AND @HasOpenComplain = 0
				AND @HasInprogressComplain = 0
				AND @HasCloseComplain = 0
				AND @HasPendingInquiry = 0
				AND @HasInProgressInquiry = 0
				AND @HasCompletedInquiry = 0
				AND @HasNurtureInquiry = 0
				AND @HasDisqualifiedInquiry = 0
				AND @HasClosedInquiry = 0
				AND @HasUnassignedInquiry = 0
				AND @HasReadyToManufacturerCount = 0
				AND @HasManufacturingOrderCount = 0
				AND @HasReadyToDeliveryCount = 0
				AND @HasFactoryDelivered = 0
				)
		BEGIN
			-- User has no permissions. Output default zeroes and gracefully exit.
			SELECT @CustomerCount AS CustomerCount
				,@InteriorCount AS InteriorCount
				,@ProductCount AS ProductCount
				,@OfferedProductCount AS OfferedProductCount
				,@Inquiries AS Inquiries
				,@PendingOrders AS PendingOrders
				,@ApprovedOrders AS ApprovedOrders
				,@InprogressOrders AS InprogressOrders
				,@DeliveredRetailerOrders AS DeliveredRetailerOrders
				,@ArchiveOrders AS ArchiveOrders
				,@OnHoldOrders AS OnHoldOrders
				,@Receivables AS Receivables
				,@InquiriesWholesalerOrder AS InquiriesWholesalerOrder
				,@PendingWholesalerOrders AS PendingWholesalerOrders
				,@ApprovedWholesalerOrders AS ApprovedWholesalerOrders
				,@InProgressWholesalerOrders AS InProgressWholesalerOrders
				,@DeliveredWholesalerOrders AS DeliveredWholesalerOrders
				,@ArchiveWholesalerOrders AS ArchiveWholesalerOrders
				,@OnHoldWholesalerOrders AS OnHoldWholesalerOrders
				,@ReceivablesWholesalerCount AS ReceivablesWholesalerCount
				,@OpenComplain AS OpenComplain
				,@InprogressComplain AS InprogressComplain
				,@CloseComplain AS CloseComplain
				,@PendingInquiry AS PendingInquiry
				,@InProgressInquiry AS InProgressInquiry
				,@CompletedInquiry AS CompletedInquiry
				,@NurtureInquiry AS NurtureInquiry
				,@DisqualifiedInquiry AS DisqualifiedInquiry
				,@ClosedInquiry AS ClosedInquiry
				,@UnassignedInquiry AS UnassignedInquiry
				,@ReadyToManufacturerCount AS ReadyToManufacturerCount
				,@ManufacturingOrderCount AS ManufacturingOrderCount
				,@ReadyToDeliveryCount AS ReadyToDeliveryCount
				,@DeliveredCount AS DeliveredCount;
		END
		ELSE
		BEGIN
			-- User has permissions. Process data.
			-- Setup variables
			DECLARE @FilterByLocation BIT = 0
				,@Today DATE = CAST(GETDATE() AS DATE)
				,@HasAnyRetailerOrder BIT = (@HasInquiries | @HasPendingOrders | @HasApprovedOrders | @HasInprogressOrders | @HasDeliveredRetailerOrders | @HasArchiveOrders | @HasOnHoldOrders | @HasReceivables)
				,@HasAnyWholesalerOrder BIT = (@HasInquiriesWholesalerOrder | @HasPendingWholesalerOrders | @HasApprovedWholesalerOrders | @HasInProgressWholesalerOrders | @HasDeliveredWholesalerOrders | @HasArchiveWholesalerOrders | @HasOnHoldWholesalerOrders | @HasReceivablesWholesalerCount)
				,@CutoffDate DATETIME2;

			-- Create temp tables for memory holding
			CREATE TABLE #AllowedLocations (LocationId BIGINT PRIMARY KEY);

			CREATE TABLE #TenantOrders (
				OrderId BIGINT PRIMARY KEY
				,OrderType SMALLINT
				,Status INT
				,IsArchive BIT
				);

			CREATE TABLE #MfgCount (Cnt INT);

			-- Determine Locations
			IF (
					@LocationId IS NOT NULL
					AND @LocationId > 0
					)
			BEGIN
				INSERT INTO #AllowedLocations (LocationId)
				VALUES (@LocationId);

				SET @FilterByLocation = 1;
			END
			ELSE
			BEGIN
				INSERT INTO #AllowedLocations (LocationId)
				SELECT DISTINCT LocationID
				FROM dbo.LocationUserMapping WITH (NOLOCK)
				WHERE UserID = @UserId
					AND LocationID IS NOT NULL;

				IF EXISTS (
						SELECT 1
						FROM #AllowedLocations
						)
					SET @FilterByLocation = 1;
			END

			-- =========================================================
			-- Products & Offered Products
			-- =========================================================
			IF (@HasProductCount = 1)
			BEGIN
				SELECT @ProductCount = COUNT(1)
				FROM dbo.Products p WITH (NOLOCK)
				INNER JOIN dbo.Categories c WITH (NOLOCK) ON p.CategoryId = c.CategoryId
				WHERE p.TenantId = @TenantId
					AND p.Status = 1
					AND c.CategoryTypeId = 1
					AND c.IsDeleted = 0
					AND c.TenantId = @TenantId;
			END

			IF (@HasOfferedProductCount = 1)
			BEGIN
				SELECT @OfferedProductCount = COUNT(DISTINCT p.ProductId)
				FROM dbo.Offers o WITH (NOLOCK)
				INNER JOIN dbo.OfferProductMapping opm WITH (NOLOCK) ON o.OfferId = opm.OfferId
				INNER JOIN dbo.Products p WITH (NOLOCK) ON opm.ProductId = p.ProductId
					AND p.TenantId = @TenantId
					AND p.Status = 1
				INNER JOIN dbo.Categories c WITH (NOLOCK) ON p.CategoryId = c.CategoryId
					AND c.CategoryTypeId = 1
					AND c.IsDeleted = 0
					AND c.TenantId = @TenantId
				WHERE o.TenantId = @TenantId
					AND o.IsDeleted = 0
					AND o.IsPublished = 1
					AND @Today BETWEEN o.StartDate
						AND o.EndDate;
			END

			-- =========================================================
			-- Orders (Retailer & Wholesaler) - High Performance Single-Pass
			-- =========================================================
			IF (
					@HasAnyRetailerOrder = 1
					OR @HasAnyWholesalerOrder = 1
					)
			BEGIN
				INSERT INTO #TenantOrders (
					OrderId
					,OrderType
					,Status
					,IsArchive
					)
				SELECT o.OrderId
					,o.OrderType
					,o.Status
					,o.IsArchive
				FROM dbo.Orders o WITH (NOLOCK)
				WHERE o.TenantId = @TenantId
					AND (
						(
							@HasAnyRetailerOrder = 1
							AND o.OrderType = 1
							)
						OR (
							@HasAnyWholesalerOrder = 1
							AND o.OrderType = 2
							)
						)
					AND (
						@FilterByLocation = 0
						OR EXISTS (
							SELECT 1
							FROM #AllowedLocations loc
							WHERE loc.LocationId = o.LocationId
							)
						)
				OPTION (RECOMPILE);-- Forces optimal execution plan based on runtime @FilterByLocation value

				SELECT @Inquiries = ISNULL(SUM(CASE 
								WHEN @HasInquiries = 1
									AND OrderType = 1
									AND IsArchive = 0
									AND Status = 0
									THEN 1
								ELSE 0
								END), 0)
					,@PendingOrders = ISNULL(SUM(CASE 
								WHEN @HasPendingOrders = 1
									AND OrderType = 1
									AND IsArchive = 0
									AND Status = 1
									THEN 1
								ELSE 0
								END), 0)
					,@ApprovedOrders = ISNULL(SUM(CASE 
								WHEN @HasApprovedOrders = 1
									AND OrderType = 1
									AND IsArchive = 0
									AND Status = 2
									THEN 1
								ELSE 0
								END), 0)
					,@InprogressOrders = ISNULL(SUM(CASE 
								WHEN @HasInprogressOrders = 1
									AND OrderType = 1
									AND IsArchive = 0
									AND Status = 3
									THEN 1
								ELSE 0
								END), 0)
					,@DeliveredRetailerOrders = ISNULL(SUM(CASE 
								WHEN @HasDeliveredRetailerOrders = 1
									AND OrderType = 1
									AND IsArchive = 0
									AND Status = 5
									THEN 1
								ELSE 0
								END), 0)
					,@ArchiveOrders = ISNULL(SUM(CASE 
								WHEN @HasArchiveOrders = 1
									AND OrderType = 1
									AND IsArchive = 1
									AND Status <> 9
									THEN 1
								ELSE 0
								END), 0)
					,@InquiriesWholesalerOrder = ISNULL(SUM(CASE 
								WHEN @HasInquiriesWholesalerOrder = 1
									AND OrderType = 2
									AND IsArchive = 0
									AND Status = 0
									THEN 1
								ELSE 0
								END), 0)
					,@PendingWholesalerOrders = ISNULL(SUM(CASE 
								WHEN @HasPendingWholesalerOrders = 1
									AND OrderType = 2
									AND IsArchive = 0
									AND Status = 1
									THEN 1
								ELSE 0
								END), 0)
					,@ApprovedWholesalerOrders = ISNULL(SUM(CASE 
								WHEN @HasApprovedWholesalerOrders = 1
									AND OrderType = 2
									AND IsArchive = 0
									AND Status = 2
									THEN 1
								ELSE 0
								END), 0)
					,@InProgressWholesalerOrders = ISNULL(SUM(CASE 
								WHEN @HasInProgressWholesalerOrders = 1
									AND OrderType = 2
									AND IsArchive = 0
									AND Status = 3
									THEN 1
								ELSE 0
								END), 0)
					,@DeliveredWholesalerOrders = ISNULL(SUM(CASE 
								WHEN @HasDeliveredWholesalerOrders = 1
									AND OrderType = 2
									AND IsArchive = 0
									AND Status = 5
									THEN 1
								ELSE 0
								END), 0)
					,@ArchiveWholesalerOrders = ISNULL(SUM(CASE 
								WHEN @HasArchiveWholesalerOrders = 1
									AND OrderType = 2
									AND IsArchive = 1
									AND Status <> 9
									THEN 1
								ELSE 0
								END), 0)
				FROM #TenantOrders;

				IF (
						@HasOnHoldOrders = 1
						OR @HasOnHoldWholesalerOrders = 1
						)
				BEGIN
					SELECT @OnHoldOrders = ISNULL(SUM(CASE 
									WHEN @HasOnHoldOrders = 1
										AND o.OrderType = 1
										THEN 1
									ELSE 0
									END), 0)
						,@OnHoldWholesalerOrders = ISNULL(SUM(CASE 
									WHEN @HasOnHoldWholesalerOrders = 1
										AND o.OrderType = 2
										THEN 1
									ELSE 0
									END), 0)
					FROM #TenantOrders o
					WHERE o.IsArchive = 0
						AND EXISTS (
							SELECT 1
							FROM dbo.StockOnHold s WITH (NOLOCK)
							WHERE s.OrderId = o.OrderId
								AND s.IsStockOnHold = 1
							);
				END

				IF (
						@HasReceivables = 1
						OR @HasReceivablesWholesalerCount = 1
						)
				BEGIN
					SET @CutoffDate = DATEADD(DAY, - 7, CAST(GETUTCDATE() AS DATE));

					SELECT @Receivables = ISNULL(SUM(CASE 
									WHEN @HasReceivables = 1
										AND o.OrderType = 1
										THEN 1
									ELSE 0
									END), 0)
						,@ReceivablesWholesalerCount = ISNULL(SUM(CASE 
									WHEN @HasReceivablesWholesalerCount = 1
										AND o.OrderType = 2
										THEN 1
									ELSE 0
									END), 0)
					FROM dbo.OrderSetItemReceivables r WITH (NOLOCK)
					INNER JOIN dbo.OrderSetItems osi WITH (NOLOCK) ON r.OrderSetItemId = osi.OrderSetItemId
					INNER JOIN #TenantOrders o ON osi.OrderId = o.OrderId
					WHERE o.IsArchive = 0
						AND r.CreatedUTCDate > @CutoffDate;
				END
			END

			-- =========================================================
			-- Customers & Interiors - High Performance Evaluation
			-- =========================================================
			IF (
					@HasCustomerCount = 1
					OR @HasInteriorCount = 1
					)
			BEGIN
				SELECT @CustomerCount = ISNULL(SUM(CASE 
								WHEN @HasCustomerCount = 1
									AND c.CustomerTypeId = 1
									THEN 1
								ELSE 0
								END), 0)
					,@InteriorCount = ISNULL(SUM(CASE 
								WHEN @HasInteriorCount = 1
									AND c.CustomerTypeId = 2
									THEN 1
								ELSE 0
								END), 0)
				FROM dbo.Customers c WITH (NOLOCK)
				WHERE c.TenantId = @TenantId
					AND c.IsDeleted = 0
					AND c.CustomerTypeId IN (
						1
						,2
						)
					AND (
						@FilterByLocation = 0
						OR EXISTS (
							SELECT 1
							FROM #AllowedLocations loc
							WHERE loc.LocationId = c.LocationID
							)
						)
				OPTION (RECOMPILE);
			END

			-- =========================================================
			-- Complaints - High Performance Evaluation
			-- =========================================================
			IF (
					@HasOpenComplain = 1
					OR @HasInprogressComplain = 1
					OR @HasCloseComplain = 1
					)
			BEGIN
				SELECT @OpenComplain = ISNULL(SUM(CASE 
								WHEN @HasOpenComplain = 1
									AND comp.Status = 1
									THEN 1
								ELSE 0
								END), 0)
					,@InprogressComplain = ISNULL(SUM(CASE 
								WHEN @HasInprogressComplain = 1
									AND comp.Status = 2
									THEN 1
								ELSE 0
								END), 0)
					,@CloseComplain = ISNULL(SUM(CASE 
								WHEN @HasCloseComplain = 1
									AND comp.Status = 3
									THEN 1
								ELSE 0
								END), 0)
				FROM dbo.Complains comp WITH (NOLOCK)
				LEFT JOIN dbo.Customers c WITH (NOLOCK) ON comp.CustomerId = c.CustomerId
				WHERE comp.TenantId = @TenantId
					AND comp.Status IN (
						1
						,2
						,3
						)
					AND (
						@FilterByLocation = 0
						OR EXISTS (
							SELECT 1
							FROM #AllowedLocations loc
							WHERE loc.LocationId = c.LocationID
							)
						)
				OPTION (RECOMPILE);
			END

			-- =========================================================
			-- Leads - High Performance Evaluation
			-- =========================================================
			IF (
					@HasPendingInquiry = 1
					OR @HasInProgressInquiry = 1
					OR @HasCompletedInquiry = 1
					OR @HasNurtureInquiry = 1
					OR @HasDisqualifiedInquiry = 1
					OR @HasClosedInquiry = 1
					OR @HasUnassignedInquiry = 1
					)
			BEGIN
				SELECT @PendingInquiry = ISNULL(SUM(CASE 
								WHEN @HasPendingInquiry = 1
									AND l.Status = 0
									THEN 1
								ELSE 0
								END), 0)
					,@InProgressInquiry = ISNULL(SUM(CASE 
								WHEN @HasInProgressInquiry = 1
									AND l.Status = 1
									THEN 1
								ELSE 0
								END), 0)
					,@CompletedInquiry = ISNULL(SUM(CASE 
								WHEN @HasCompletedInquiry = 1
									AND l.Status = 2
									THEN 1
								ELSE 0
								END), 0)
					,@NurtureInquiry = ISNULL(SUM(CASE 
								WHEN @HasNurtureInquiry = 1
									AND l.Status = 3
									THEN 1
								ELSE 0
								END), 0)
					,@DisqualifiedInquiry = ISNULL(SUM(CASE 
								WHEN @HasDisqualifiedInquiry = 1
									AND l.Status = 4
									THEN 1
								ELSE 0
								END), 0)
					,@ClosedInquiry = ISNULL(SUM(CASE 
								WHEN @HasClosedInquiry = 1
									AND l.Status = 5
									THEN 1
								ELSE 0
								END), 0)
					,@UnassignedInquiry = ISNULL(SUM(CASE 
								WHEN @HasUnassignedInquiry = 1
									AND l.Status = 7
									THEN 1
								ELSE 0
								END), 0)
				FROM dbo.Leads l WITH (NOLOCK)
				WHERE l.TenantId = @TenantId
					AND l.Status IN (
						0
						,1
						,2
						,3
						,4
						,5
						,7
						)
					AND (
						@FilterByLocation = 0
						OR EXISTS (
							SELECT 1
							FROM #AllowedLocations loc
							WHERE loc.LocationId = l.LocationID
							)
						)
			END

			-- =========================================================
			-- Manufacturing Dashboard External Procedures
			-- =========================================================
			IF (
					@HasReadyToManufacturerCount = 1
					OR @HasManufacturingOrderCount = 1
					OR @HasReadyToDeliveryCount = 1
					OR @HasFactoryDelivered = 1
					)
			BEGIN
				IF (@HasReadyToManufacturerCount = 1)
				BEGIN
					INSERT INTO #MfgCount (Cnt)
					EXEC dbo.GetReadyToManufacturerCountForMfgDashboard @TenantId;

					SELECT TOP 1 @ReadyToManufacturerCount = Cnt
					FROM #MfgCount;

					TRUNCATE TABLE #MfgCount;
				END

				IF (@HasManufacturingOrderCount = 1)
				BEGIN
					INSERT INTO #MfgCount (Cnt)
					EXEC dbo.GetManufacturingOrderCountForMfgDashboard @TenantId;

					SELECT TOP 1 @ManufacturingOrderCount = Cnt
					FROM #MfgCount;

					TRUNCATE TABLE #MfgCount;
				END

				IF (@HasReadyToDeliveryCount = 1)
				BEGIN
					INSERT INTO #MfgCount (Cnt)
					EXEC dbo.GetReadyToDeliveryCountForMfgDashboard @TenantId;

					SELECT TOP 1 @ReadyToDeliveryCount = Cnt
					FROM #MfgCount;

					TRUNCATE TABLE #MfgCount;
				END

				IF (@HasFactoryDelivered = 1)
				BEGIN
					INSERT INTO #MfgCount (Cnt)
					EXEC dbo.GetDeliveredCountForMfgDashboard @TenantId;

					SELECT TOP 1 @DeliveredCount = Cnt
					FROM #MfgCount;
				END
			END

			-- =========================================================
			-- Cleanup explicit Temp Tables
			-- =========================================================
			DROP TABLE IF EXISTS #AllowedLocations;

			DROP TABLE IF EXISTS #TenantOrders;

			DROP TABLE IF EXISTS #MfgCount;

			-- =========================================================
			-- Final Output Select
			-- =========================================================
			SELECT @CustomerCount AS CustomerCount
				,@InteriorCount AS InteriorCount
				,@ProductCount AS ProductCount
				,@OfferedProductCount AS OfferedProductCount
				,@Inquiries AS Inquiries
				,@PendingOrders AS PendingOrders
				,@ApprovedOrders AS ApprovedOrders
				,@InprogressOrders AS InprogressOrders
				,@DeliveredRetailerOrders AS DeliveredRetailerOrders
				,@ArchiveOrders AS ArchiveOrders
				,@OnHoldOrders AS OnHoldOrders
				,@Receivables AS Receivables
				,@InquiriesWholesalerOrder AS InquiriesWholesalerOrder
				,@PendingWholesalerOrders AS PendingWholesalerOrders
				,@ApprovedWholesalerOrders AS ApprovedWholesalerOrders
				,@InProgressWholesalerOrders AS InProgressWholesalerOrders
				,@DeliveredWholesalerOrders AS DeliveredWholesalerOrders
				,@ArchiveWholesalerOrders AS ArchiveWholesalerOrders
				,@OnHoldWholesalerOrders AS OnHoldWholesalerOrders
				,@ReceivablesWholesalerCount AS ReceivablesWholesalerCount
				,@OpenComplain AS OpenComplain
				,@InprogressComplain AS InprogressComplain
				,@CloseComplain AS CloseComplain
				,@PendingInquiry AS PendingInquiry
				,@InProgressInquiry AS InProgressInquiry
				,@CompletedInquiry AS CompletedInquiry
				,@NurtureInquiry AS NurtureInquiry
				,@DisqualifiedInquiry AS DisqualifiedInquiry
				,@ClosedInquiry AS ClosedInquiry
				,@UnassignedInquiry AS UnassignedInquiry
				,@ReadyToManufacturerCount AS ReadyToManufacturerCount
				,@ManufacturingOrderCount AS ManufacturingOrderCount
				,@ReadyToDeliveryCount AS ReadyToDeliveryCount
				,@DeliveredCount AS DeliveredCount;
		END
	END TRY

	BEGIN CATCH
		-- Ensure temp tables are dropped if an error occurs mid-execution
		DROP TABLE IF EXISTS #AllowedLocations;

		DROP TABLE IF EXISTS #TenantOrders;

		DROP TABLE IF EXISTS #MfgCount;

			DECLARE @ObjectName VARCHAR(500)
				,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END;

GO

