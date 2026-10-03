#Requires -Version 7.0
<#
.SYNOPSIS
    Installs apps + test apps into a Business Central environment and runs the test suite via bcdevenv.

.DESCRIPTION
    This is the test-running half of the bcdevenv-based CI/CD for BCApps. It replaces the
    BcContainerHelper `Run-TestsInBcContainer` call inside AL-Go's RunPipeline. The flow is:

        1. `bcdevenv install-app` - publish + sync + install the test toolkit, then the apps under
           test, then the test apps, into the running NST (order matters: dependencies first).
        2. `bcdevenv run-tests`   - run the suite and emit a JUnit report, exiting non-zero on any
           failure so the step (and the build) fails.

    `run-tests` has two input paths, both producing the same JUnit report:
        * -FromXml  : convert an xUnit result document the environment's test tool produced (no live
                      server call - the reliable CI path).
        * live      : invoke the toolkit's runner web service over the NST OData v4 endpoint.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $BcDevEnvExe,
    [string] $ServerInstance = 'BC',
    [string] $ODataUrl = '',
    [string] $TestToolkitFolder = '',
    [string] $AppsFolder = '',
    [string] $TestAppsFolder = '',
    [string] $InstallApps = 'true',
    [string] $ResultFile = 'TestResults/junit.xml',
    [string] $FromXml = '',
    [string] $ServiceName = 'BcDevEnvTestRunner',
    [string] $ExtensionId = '',
    [string] $TestCodeunitFilter = '',
    [string] $AllowFailures = 'false'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

function Set-Output([string] $Name, [string] $Value) {
    Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "$Name=$Value"
}

function Invoke-BcDevEnv {
    param(
        [Parameter(Mandatory = $true)][string[]] $Arguments,
        [switch] $PassThruExitCode
    )
    Write-Host "::group::bcdevenv $($Arguments -join ' ')"
    & $BcDevEnvExe @Arguments
    $code = $LASTEXITCODE
    Write-Host '::endgroup::'
    if ($PassThruExitCode) { return $code }
    if ($code -ne 0) { throw "bcdevenv $($Arguments[0]) failed with exit code $code." }
    return 0
}

function Get-AppFiles([string] $Folder) {
    if (-not $Folder -or -not (Test-Path $Folder)) { return @() }
    return Get-ChildItem -Path $Folder -Filter '*.app' -File -Recurse | Sort-Object Name
}

if (-not (Test-Path $BcDevEnvExe)) {
    throw "bcdevenv executable not found at '$BcDevEnvExe'."
}

# ---------------------------------------------------------------------------
# 1. Install the toolkit, then the apps under test, then the test apps.
# ---------------------------------------------------------------------------
if ($InstallApps -eq 'true') {
    $ordered = @()
    $ordered += Get-AppFiles $TestToolkitFolder
    $ordered += Get-AppFiles $AppsFolder
    $ordered += Get-AppFiles $TestAppsFolder

    if ($ordered.Count -eq 0) {
        Write-Host "::warning::No .app packages found under the toolkit/apps/test folders; nothing to install."
    }
    else {
        $installArgs = @('install-app', '--server-instance', $ServerInstance)
        foreach ($app in $ordered) { $installArgs += @('--app-file', $app.FullName) }
        Write-Host "Installing $($ordered.Count) app package(s) into instance '$ServerInstance'."
        Invoke-BcDevEnv -Arguments $installArgs | Out-Null
    }
}

# ---------------------------------------------------------------------------
# 2. Run the tests -> JUnit report.
# ---------------------------------------------------------------------------
$runArgs = @('run-tests', '--result-file', $ResultFile)
if ($AllowFailures -eq 'true') { $runArgs += '--allow-failures' }

if ($FromXml) {
    if (-not (Test-Path $FromXml)) { throw "xUnit result document not found: '$FromXml'." }
    $runArgs += @('--from-xml', $FromXml)
}
else {
    if (-not $ODataUrl) { $ODataUrl = "http://localhost:7048/$ServerInstance/ODataV4" }
    $runArgs += @('--odata-url', $ODataUrl, '--service-name', $ServiceName)
    if ($ExtensionId) { $runArgs += @('--extension', $ExtensionId) }
    if ($TestCodeunitFilter) { $runArgs += @('--test-codeunit', $TestCodeunitFilter) }
}

$exit = Invoke-BcDevEnv -Arguments $runArgs -PassThruExitCode

$resolved = $ResultFile
if (-not [System.IO.Path]::IsPathRooted($resolved)) {
    $resolved = Join-Path (Get-Location) $ResultFile
}
Set-Output 'resultFile' $resolved

if ($exit -ne 0) {
    throw "Tests failed (bcdevenv run-tests exit code $exit). See the summary above and the JUnit report at '$resolved'."
}
Write-Host "Tests passed. JUnit report: $resolved"
