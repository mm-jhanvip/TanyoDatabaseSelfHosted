	CREATE FUNCTION [dbo].[fnLeaveSummary] (
		@startdate date
		,@enddate date
		,@optional_user_id INT

		)
	RETURNS TABLE
WITH ENCRYPTION
AS
	RETURN ( SELECT * FROM [dbo].[LeaveApplications]
					WHERE (StartDate BETWEEN @startdate AND @enddate) 
							AND UserID = @optional_user_id
				)

GO

