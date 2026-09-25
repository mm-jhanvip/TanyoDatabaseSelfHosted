-- =============================================
-- Author       : MagnusMinds
-- Create date  : 07-Aug-2026
-- Description  : List Tenant App Versions with filters, pagination and sorting
-- =============================================
/*
    -- Get all records
    EXEC [dbo].[ListTenantAppVersion]
         @TenantId = NULL
        ,@TenantName = NULL
        ,@AppVersion = NULL
        ,@ForceUpdate = NULL
        ,@Maintenance = NULL
        ,@PageIndex = 1
        ,@PageSize = 50
        ,@SortBy = 'TenantName'
        ,@SortOrder = 'ASC'
*/
CREATE PROCEDURE [dbo].[ListTenantAppVersion]
(
    @TenantId INT = NULL
    ,@TenantName VARCHAR(200) = NULL
    ,@AppVersion VARCHAR(100) = NULL
    ,@ForceUpdate BIT = NULL
    ,@Maintenance BIT = NULL
    ,@AppBundleId VARCHAR(200) = NULL
    ,@PageIndex INT = 1
    ,@PageSize INT = 50
    ,@SortBy VARCHAR(50) = 'TenantName'
    ,@SortOrder VARCHAR(4) = 'ASC'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- =============================================
        -- Validate Pagination
        -- =============================================
        IF ISNULL(@PageIndex, 0) <= 0
            SET @PageIndex = 1;

        IF ISNULL(@PageSize, 0) <= 0
            SET @PageSize = 50;


        -- =============================================
        -- Validate Sorting
        -- =============================================
        IF ISNULL(@SortBy, '') = ''
            SET @SortBy = 'TenantName';

        IF UPPER(ISNULL(@SortOrder, '')) NOT IN ('ASC', 'DESC')
            SET @SortOrder = 'ASC';


        -- =============================================
        -- Main Query
        -- =============================================
        SELECT
            tav.TenantAppVersionId
            ,tav.TenantId
            ,t.TenantName AS TenantName
            ,t.AppBundleId As AppBundleId
            ,tav.DeviceType AS DeviceType
            ,tav.AppVersion AS AppVersion
            ,tav.IsForceUpdate AS ForceUpdate
            ,tav.IsMaintenance AS Maintenance
            ,COUNT(1) OVER (PARTITION BY 1) AS TotalCount
        FROM [dbo].[TenantAppVersion] tav WITH (NOLOCK)
        INNER JOIN [dbo].[Tenants] t WITH (NOLOCK)
            ON t.TenantId = tav.TenantId
        WHERE
            (
                @TenantId IS NULL
                OR @TenantId <= 0
                OR tav.TenantId = @TenantId
            )
            AND
            (
                @TenantName IS NULL
                OR LTRIM(RTRIM(@TenantName)) = ''
                OR ISNULL(t.TenantName, '') LIKE '%' + LTRIM(RTRIM(@TenantName)) + '%'
            )
            AND
            (
                @AppVersion IS NULL
                OR LTRIM(RTRIM(@AppVersion)) = ''
                OR ISNULL(tav.AppVersion, '') LIKE '%' + LTRIM(RTRIM(@AppVersion)) + '%'
            )
            AND
            (
                @ForceUpdate IS NULL
                OR tav.IsForceUpdate = @ForceUpdate
            )
            AND
            (
                @Maintenance IS NULL
                OR tav.IsMaintenance = @Maintenance
            )
            AND 
            (
                @AppBundleId IS NULL 
                OR (@AppBundleId = 'TanyoApp' AND AppBundleId = 'io.ionic.TanyoERP')
                OR (@AppBundleId = 'WhiteLabelApp' AND AppBundleId <> 'io.ionic.TanyoERP')
            )

        ORDER BY

            -- Tenant Name
            CASE
                WHEN @SortBy = 'TenantName'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN ISNULL(t.TenantName, '')
            END ASC,

            CASE
                WHEN @SortBy = 'TenantName'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN ISNULL(t.TenantName, '')
            END DESC,

            -- App Bundle Id
            CASE
                WHEN @SortBy = 'AppBundleId'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN t.AppBundleId
            END ASC,
            CASE
                WHEN @SortBy = 'AppBundleId'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN t.AppBundleId
            END DESC,


            -- Tenant Id
            CASE
                WHEN @SortBy = 'TenantId'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN tav.TenantId
            END ASC,

            CASE
                WHEN @SortBy = 'TenantId'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN tav.TenantId
            END DESC,


            -- Device Type
            CASE
                WHEN @SortBy = 'DeviceType'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN ISNULL(tav.DeviceType, '')
            END ASC,

            CASE
                WHEN @SortBy = 'DeviceType'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN ISNULL(tav.DeviceType, '')
            END DESC,


            -- App Version
            CASE
                WHEN @SortBy = 'AppVersion'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN ISNULL(tav.AppVersion, '')
            END ASC,

            CASE
                WHEN @SortBy = 'AppVersion'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN ISNULL(tav.AppVersion, '')
            END DESC,


            -- Force Update
            CASE
                WHEN @SortBy = 'ForceUpdate'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN tav.IsForceUpdate
            END ASC,

            CASE
                WHEN @SortBy = 'ForceUpdate'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN tav.IsForceUpdate
            END DESC,


            -- Maintenance
            CASE
                WHEN @SortBy = 'Maintenance'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN tav.IsMaintenance
            END ASC,

            CASE
                WHEN @SortBy = 'Maintenance'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN tav.IsMaintenance
            END DESC,


            -- Last Modified Date
            CASE
                WHEN @SortBy = 'LastModifiedDate'
                    AND UPPER(@SortOrder) = 'ASC'
                THEN tav.LastModifiedDate
            END ASC,

            CASE
                WHEN @SortBy = 'LastModifiedDate'
                    AND UPPER(@SortOrder) = 'DESC'
                THEN tav.LastModifiedDate
            END DESC,


            -- Default ordering / stable pagination
            tav.TenantAppVersionId DESC

        OFFSET (@PageIndex - 1) * @PageSize ROWS

        FETCH NEXT @PageSize ROWS ONLY;

    END TRY

    BEGIN CATCH

        DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ObjectName VARCHAR(500)

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()
			,@ObjectName = OBJECT_NAME(@@PROCID)

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMessage

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)

    END CATCH
END

GO

