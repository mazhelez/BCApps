[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'runParameters', Justification = 'The parameter is always passed to the script')]
param (
    [Parameter(Mandatory=$true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "Microsoft.Dynamics.BusinessCentral.Translations"

if ($newVersion) {
    return @{
        'Files' = @("build/Packages.json")
        'Message' = "Update translation package version. New value: $newVersion"
    }
}