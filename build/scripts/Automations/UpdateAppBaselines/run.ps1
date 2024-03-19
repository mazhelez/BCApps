Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$newVersion = Update-PackageVersion -PackageName "AppBaselines-BCArtifacts"

if ($newVersion) {
    return @{
        'Files' = @("build/Packages.json")
        'Message' = "Update app baselines package version. New version: $newVersion"
    }
}