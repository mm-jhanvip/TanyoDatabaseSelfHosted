CREATE PROCEDURE [dbo].[SchedulerAttendanceComplete]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @Today DATE = CONVERT(DATE, GETDATE())
        ,@SYSDATETIMEOFFSET DATETIMEOFFSET = SYSDATETIMEOFFSET()
        ,@GETUTCDATE DATETIME = GETUTCDATE()

    DECLARE @SysUser BIGINT = NULL

    SELECT @SysUser = MIN(U.UserId)
    FROM AspNetUsers U WITH (NOLOCK)
    LEFT JOIN AspNetUserRoles UR WITH (NOLOCK) ON UR.UserId = U.Id
    LEFT JOIN AspNetRoles R WITH (NOLOCK) ON R.Id = UR.RoleId
    WHERE LOWER(R.Name) LIKE 'systemuser%'


    SELECT 
        A.AttendanceId,
        A.UserId,
        UTM.TenantId,
        A.StartDate
    INTO #MissingAttendance
    FROM Attendance A WITH (NOLOCK)
    INNER JOIN AspNetUsers U WITH (NOLOCK) ON U.UserId = A.UserId
    INNER JOIN UserTenantMapping UTM WITH (NOLOCK) ON U.UserId = UTM.UserId
    WHERE CONVERT(DATE, A.StartDate) = @Today
      AND A.EndDate IS NULL
      AND U.IsActive = 1
      AND U.IsDeleted = 0;

    ;With FirstPunch AS
    (
        SELECT 
            MA.AttendanceId,
            MA.TenantId,
            ATT.StartDate,
            MA.UserId,
            DATEADD(MINUTE, 1410, MA.StartDate) AS EndDateCalc,
            ROW_NUMBER() OVER (
                PARTITION BY MA.UserId
                ORDER BY ATT.StartDate ASC
            ) AS RN
        FROM #MissingAttendance MA
        INNER JOIN Attendance ATT WITH (NOLOCK)
            ON ATT.AttendanceId = MA.AttendanceId
    )
    SELECT X.AttendanceId,
           X.TenantId,
           X.UserId,
           X.StartDate,
           X.EndDateCalc
    INTO #AttendanceToUpdate
    FROM FirstPunch X
    WHERE X.RN = 1;

    UPDATE A
    SET 
        A.EndDate = AU.EndDateCalc,
        A.UpdatedBy = ISNULL(@SysUser, 1),
        A.UpdatedDate = @SYSDATETIMEOFFSET,
        A.UpdatedUTCDate = @GETUTCDATE
    FROM Attendance A WITH (NOLOCK)
    INNER JOIN #MissingAttendance MA
        ON MA.AttendanceId = A.AttendanceId
    INNER JOIN #AttendanceToUpdate AU
        ON AU.UserId = MA.UserId

    DROP TABLE IF EXISTS #MissingAttendance;
    DROP TABLE IF EXISTS #AttendanceToUpdate;

    END TRY

    BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg VARCHAR(MAX);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
    END CATCH

END

GO

