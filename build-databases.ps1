$ErrorActionPreference = 'Stop'

dotnet build "$PSScriptRoot\TanyoLogsDB\TanyoLogsDB.sqlproj"
dotnet build "$PSScriptRoot\TanyoAppDB\TanyoAppDB.sqlproj"
