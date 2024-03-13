<#
.SYNOPSIS
    Updates the BCArtifact version in the AL-Go settings file (artifact property)
.DESCRIPTION
    This script will update the BCArtifact version in the AL-Go settings file (artifact property) to the latest version available on the BC artifacts feed (bcinsider/bcartifacts storage account).
.PARAMETER TargetBranch
    Unused. Always passed by the automation handler.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TargetBranch', Justification = 'Always passed by the automations handler')]
param(
    [Parameter(Mandatory = $false)]
    [string]$TargetBranch
)

# BC Container Helper is needed to fetch the latest artifact version
Install-Module -Name BcContainerHelper -AllowPrerelease -Force
Import-Module BcContainerHelper

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

function UpdateBCArtifactVersion() {
    $artifactValue = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    if ($artifactValue -and ($artifactValue -match "\d+\.\d+\.\d+\.\d+")) {
        $currentArtifactVersion = $Matches[0]
    } else {
        throw "Could not find BCArtifact version: $artifactValue"
    }

    Write-Host "Current BCArtifact version: $currentArtifactVersion"

    $currentVersion = Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go
    $latestArtifactVersion = Get-LatestBCArtifactVersion -minimumVersion $currentVersion

    Write-Host "Latest BCArtifact version: $latestArtifactVersion"

    if($latestArtifactVersion -gt $currentArtifactVersion) {
        Write-Host "Updating BCArtifact version from $currentArtifactVersion to $latestArtifactVersion"

        $artifactValue = $artifactValue -replace $currentArtifactVersion, $latestArtifactVersion
        Set-ConfigValue -Key "artifact" -Value $artifactValue -ConfigType AL-Go

        return $latestArtifactVersion
    }

    return $null
}

$newVersion = UpdateBCArtifactVersion

if ($newVersion) {
    return @{
        'Files' = @(".github/AL-Go-Settings.json")
        'Message' = "Update BCArtifact version in AL-Go settings file. New version: $newVersion"
    }
}
