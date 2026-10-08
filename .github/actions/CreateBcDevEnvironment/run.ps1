#Requires -Version 7.0
<#
.SYNOPSIS
    Creates and starts a Business Central environment for CI using the bcdevenv CLI.

.DESCRIPTION
    This is the environment-creation half of the bcdevenv-based CI/CD for BCApps. It replaces the
    BcContainerHelper container that AL-Go's RunPipeline creates. The flow is:

        1. Resolve a platform artifact version (explicit, or the latest build of a major from the
           public platform index) and download + extract the platform artifact.
        2. `bcdevenv verify`      - sanity-check the artifact (no SQL/Docker needed).
        3. `bcdevenv create-env`  - build a fresh, empty platform database from the artifact (.bak).
        4. `bcdevenv build-image` - bake the .bak + the SAME artifact's binaries into a Windows image.
        5. `bcdevenv start`       - run a container and wait until the client services answer.

    Because the schema (.bak) and the service tier come from one artifact, they cannot drift - which
    is the whole reason bcdevenv exists.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $BcDevEnvExe,
    [string] $PlatformVersion = '',
    [string] $PlatformMajor = '',
    [string] $PlatformArtifactUrl = '',
    [string] $ArtifactCacheDir = '',
    [string] $SqlServer = 'localhost',
    [string] $DatabaseName = 'CRONUS',
    [string] $EnvironmentName = '',
    [string] $ServerInstance = 'BC',
    [string] $ContainerName = 'bcdevenv',
    [string] $ImageTag = '',
    [string] $Port = '7046',
    [string] $ODataPort = '7048',
    [string] $LicenseFile = '',
    [string] $StartContainer = 'true'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

# The same public platform feed bcdevenv's own integration tests use.
$PlatformFeed = 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform'

function Set-Output([string] $Name, [string] $Value) {
    Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "$Name=$Value"
}

function Invoke-BcDevEnv {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)
    Write-Host "::group::bcdevenv $($Arguments -join ' ')"
    & $BcDevEnvExe @Arguments
    $code = $LASTEXITCODE
    Write-Host '::endgroup::'
    if ($code -ne 0) {
        throw "bcdevenv $($Arguments[0]) failed with exit code $code."
    }
}

if (-not (Test-Path $BcDevEnvExe)) {
    throw "bcdevenv executable not found at '$BcDevEnvExe'. Build it in the workflow and pass its path as bcDevEnvExe."
}

# ---------------------------------------------------------------------------
# 1. Resolve the platform version.
# ---------------------------------------------------------------------------
if (-not $PlatformVersion -and -not $PlatformArtifactUrl) {
    Write-Host "Resolving platform version from the platform index..."
    $index = Invoke-RestMethod -Uri "$PlatformFeed/indexes/platform.json" -TimeoutSec 120
    $entries = $index | Where-Object { $_.Version -as [version] } |
        ForEach-Object { [pscustomobject]@{ Version = [version]$_.Version; Raw = $_.Version } }

    if ($PlatformMajor) {
        $entries = $entries | Where-Object { $_.Version.Major -eq [int]$PlatformMajor }
        if (-not $entries) { throw "No platform version found for major '$PlatformMajor' in the index." }
    }
    $PlatformVersion = ($entries | Sort-Object Version -Descending | Select-Object -First 1).Raw
    Write-Host "Resolved platform version: $PlatformVersion"
}

# ---------------------------------------------------------------------------
# 2. Download + extract the platform artifact.
# ---------------------------------------------------------------------------
if (-not $ArtifactCacheDir) {
    $ArtifactCacheDir = Join-Path ([System.IO.Path]::GetTempPath()) 'bcdevenv-artifacts'
}
New-Item -ItemType Directory -Force -Path $ArtifactCacheDir | Out-Null

if (-not $PlatformArtifactUrl) {
    $PlatformArtifactUrl = "$PlatformFeed/$PlatformVersion/platform"
}
if (-not $PlatformVersion) {
    # An explicit URL was supplied; use a stable folder name derived from it.
    $PlatformVersion = [System.IO.Path]::GetFileNameWithoutExtension(($PlatformArtifactUrl -split '/')[-2])
    if (-not $PlatformVersion) { $PlatformVersion = 'platform' }
}

$platformPath = Join-Path $ArtifactCacheDir $PlatformVersion
$marker = Join-Path $platformPath '.extracted'
if (Test-Path $marker) {
    Write-Host "Using cached platform artifact: $platformPath"
}
else {
    $zip = Join-Path $ArtifactCacheDir "$PlatformVersion-platform.zip"
    Write-Host "Downloading platform artifact from $PlatformArtifactUrl ..."
    Invoke-WebRequest -Uri $PlatformArtifactUrl -OutFile $zip -TimeoutSec 1800
    if (Test-Path $platformPath) { Remove-Item $platformPath -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $platformPath | Out-Null
    Write-Host "Extracting to $platformPath ..."
    Expand-Archive -Path $zip -DestinationPath $platformPath -Force
    Set-Content -Path $marker -Value (Get-Date -Format o)
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
}

$env:BCDEVENV_PLATFORM = $platformPath
Write-Host "BCDEVENV_PLATFORM = $platformPath"

# ---------------------------------------------------------------------------
# 3. verify + create-env.
# ---------------------------------------------------------------------------
Invoke-BcDevEnv -Arguments @('verify', '--platform', $platformPath)

$createArgs = @('create-env', '--platform', $platformPath, '--database-name', $DatabaseName, '--sql-server', $SqlServer)
if ($EnvironmentName) { $createArgs += @('--name', $EnvironmentName) }
Invoke-BcDevEnv -Arguments $createArgs

# Recover the environment name create-env chose (<country>-<version>) when it was not supplied.
if (-not $EnvironmentName) {
    $bcDevEnvHome = if ($env:BCDEVENV_HOME) { $env:BCDEVENV_HOME } else { Join-Path $env:LOCALAPPDATA 'bcdevenv' }
    $manifest = Get-ChildItem -Path $bcDevEnvHome -Recurse -Filter 'manifest.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($manifest) {
        $EnvironmentName = (Get-Content $manifest.FullName -Raw | ConvertFrom-Json).Name
    }
}
Write-Host "Environment name: $EnvironmentName"

$odataUrl = ''
$startedContainer = ''

if ($StartContainer -eq 'true') {
    # -----------------------------------------------------------------------
    # 4. build-image + 5. start.
    # -----------------------------------------------------------------------
    if (-not $ImageTag) { $ImageTag = "bcdevenv:$PlatformVersion" }

    $imageArgs = @('build-image', '--env', $EnvironmentName, '--server-instance', $ServerInstance, '--tag', $ImageTag)
    if ($LicenseFile) { $imageArgs += @('--license', $LicenseFile) }
    Invoke-BcDevEnv -Arguments $imageArgs

    # bcdevenv `start` publishes three host ports: the client-services port (--port -> container 7046)
    # plus fixed OData (7048:7048) and developer-services (7049:7049) mappings. --port must therefore
    # never be 7048 or 7049, or `docker run` fails with a duplicate host-port binding. OData v4 is
    # reached on $ODataPort (host 7048), which is what the readiness probe and the test action use.
    Invoke-BcDevEnv -Arguments @('start', '--image', $ImageTag, '--name', $ContainerName, '--port', $Port, '--detach')
    $startedContainer = $ContainerName

    # Wait for the environment to answer on its OData v4 endpoint (the same URL the test action uses).
    $odataUrl = "http://localhost:$ODataPort/$ServerInstance/ODataV4"
    Write-Host "Waiting for the environment to become ready at $odataUrl ..."
    $deadline = (Get-Date).AddMinutes(20)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri "$odataUrl/`$metadata" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { $ready = $true; break }
        }
        catch {
            Start-Sleep -Seconds 15
        }
    }
    if (-not $ready) {
        Write-Host "::warning::The environment did not report ready within the timeout; downstream steps may still succeed once it warms up."
    }
    else {
        Write-Host "Environment is ready."
    }
}

# ---------------------------------------------------------------------------
# Outputs.
# ---------------------------------------------------------------------------
Set-Output 'platformPath'    $platformPath
Set-Output 'platformVersion' $PlatformVersion
Set-Output 'environmentName' $EnvironmentName
Set-Output 'containerName'   $startedContainer
Set-Output 'serverInstance'  $ServerInstance
Set-Output 'odataUrl'        $odataUrl
