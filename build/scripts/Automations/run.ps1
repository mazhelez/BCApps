param(
    [Parameter(Mandatory=$true)]
    [string] $PackageFilter = '*'
)

Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$baseFolder = Get-BaseFolder

$packagesFolder = Join-Path $baseFolder "build/scripts/Automations"
$packagePaths = Get-ChildItem -Path $packagesFolder -Directory -Filter $PackageFilter

$availableUpdates = @()
foreach ($packagePath in $packagePaths) {
    $packageUpdates = . "$packagePath\UpdatePackage.ps1"

    if ($packageUpdates) {
        $availableUpdates += $packageUpdates
    }
}




