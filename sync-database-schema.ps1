param(
    [string]$Server = '74.225.222.125,1983',
    [string]$UserName = 'harsh',
    [string]$StagingPath = (Join-Path $env:TEMP 'TanyoDatabase-schema-sync'),
    [switch]$Apply,
    [switch]$UseExistingStaging
)

$ErrorActionPreference = 'Stop'

$sqlPackage = 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\SqlPackage.exe'
$passwordPointer = [IntPtr]::Zero

function Sync-ObjectFolder {
    param(
        [string]$Source,
        [string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $sourceFiles = Get-ChildItem $Source -Recurse -File
    $destinationFiles = Get-ChildItem $Destination -Recurse -File
    $sourceRelativePaths = $sourceFiles | ForEach-Object { $_.FullName.Substring($Source.Length + 1) }

    foreach ($file in $destinationFiles) {
        $relativePath = $file.FullName.Substring($Destination.Length + 1)
        if ($relativePath -notin $sourceRelativePaths) {
            Remove-Item $file.FullName -Force
        }
    }

    foreach ($file in $sourceFiles) {
        $relativePath = $file.FullName.Substring($Source.Length + 1)
        $targetFile = Join-Path $Destination $relativePath
        $targetDirectory = Split-Path $targetFile
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        Copy-Item $file.FullName $targetFile -Force
    }
}

if (-not (Test-Path $sqlPackage)) {
    throw "SqlPackage was not found at $sqlPackage"
}

try {
    if (-not $UseExistingStaging) {
        $securePassword = Read-Host "SQL password for $UserName" -AsSecureString
        $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    }
    if (-not $UseExistingStaging) {
        Remove-Item $StagingPath -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $StagingPath | Out-Null

        foreach ($database in @('TanyoApp', 'TanyoLogs')) {
            $targetPath = Join-Path $StagingPath $database
            $arguments = @(
                '/Action:Extract'
                "/SourceServerName:$Server"
                "/SourceDatabaseName:$database"
                "/SourceUser:$UserName"
                "/SourcePassword:$password"
                "/TargetFile:$targetPath"
                '/p:ExtractTarget=SqlProject'
                '/p:VerifyExtraction=False'
                '/SourceTrustServerCertificate:True'
            )

            & $sqlPackage @arguments
            if ($LASTEXITCODE -ne 0) {
                throw "Schema extraction failed for $database with exit code $LASTEXITCODE"
            }
        }
    }

    if (-not (Test-Path (Join-Path $StagingPath 'TanyoApp')) -or -not (Test-Path (Join-Path $StagingPath 'TanyoLogs'))) {
        throw "Both staged database projects must exist at $StagingPath"
    }

    if ($Apply) {
        $appRoot = Join-Path $PSScriptRoot 'TanyoAppDB'
        $logsRoot = Join-Path $PSScriptRoot 'TanyoLogsDB'
        $appStage = Join-Path $StagingPath 'TanyoApp'
        $logsStage = Join-Path $StagingPath 'TanyoLogs'

        foreach ($mapping in @(
            @{ Source = (Join-Path $appStage 'DatabaseTriggers'); Destination = (Join-Path $appRoot 'DatabaseTriggers') }
            @{ Source = (Join-Path $appStage 'dbo\Functions'); Destination = (Join-Path $appRoot 'Functions') }
            @{ Source = (Join-Path $appStage 'dbo\StoredProcedures'); Destination = (Join-Path $appRoot 'StoredProcedures') }
            @{ Source = (Join-Path $appStage 'dbo\Synonyms'); Destination = (Join-Path $appRoot 'Synonyms') }
            @{ Source = (Join-Path $appStage 'dbo\Tables'); Destination = (Join-Path $appRoot 'Tables') }
            @{ Source = (Join-Path $appStage 'dbo\UserDefinedTypes'); Destination = (Join-Path $appRoot 'UserDefinedTypes') }
            @{ Source = (Join-Path $appStage 'dbo\Views'); Destination = (Join-Path $appRoot 'Views') }
            @{ Source = (Join-Path $appStage 'HangFire'); Destination = (Join-Path $appRoot 'HangFire') }
            @{ Source = (Join-Path $logsStage 'dbo\StoredProcedures'); Destination = (Join-Path $logsRoot 'StoredProcedures') }
            @{ Source = (Join-Path $logsStage 'dbo\Synonyms'); Destination = (Join-Path $logsRoot 'Synonyms') }
            @{ Source = (Join-Path $logsStage 'dbo\Tables'); Destination = (Join-Path $logsRoot 'Tables') }
        )) {
            Sync-ObjectFolder -Source $mapping.Source -Destination $mapping.Destination
        }
    }

    Write-Output "Schema projects staged at $StagingPath"
}
finally {
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
    $password = $null
}