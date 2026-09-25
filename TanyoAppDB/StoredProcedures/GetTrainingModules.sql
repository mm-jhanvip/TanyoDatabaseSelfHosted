/*
exec GetTrainingModules
*/
CREATE   PROCEDURE dbo.GetTrainingModules
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TM.TrainingModuleId,
        TM.TrainingModuleName,
        TM.ModuleDisplayOrder,
        (
            SELECT
                TMV.TrainingModuleVideoId,
                TMV.TrainingModuleVideoName,
                TMV.TrainingModuleVIdeoUrl,
                TMV.VideoDisplayOrder
            FROM TrainingModuleVideo TMV WITH (NOLOCK)
            WHERE TMV.TrainingModuleId = TM.TrainingModuleId
                  AND TMV.IsDeleted = 0
            ORDER BY TMV.VideoDisplayOrder
            FOR JSON PATH
        ) AS ModuleVideoList
    FROM TrainingModule TM WITH (NOLOCK)
    WHERE TM.IsDeleted = 0
    ORDER BY TM.ModuleDisplayOrder
END

GO

