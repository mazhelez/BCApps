param(
    [Parameter(Mandatory=$true)]
    [string[]] $Include,
    [Parameter(Mandatory=$true)]
    [string] $Repository,
    [Parameter(Mandatory=$true)]
    [string] $TargetBranch,
    [Parameter(Mandatory=$true)]
    [string] $Actor
)

function RunAutomation {
    param(
        [Parameter(Mandatory=$true)]
        [string] $AutomationName
    )

    $automationPath = Join-Path $PSScriptRoot $AutomationName
    try {
        $automationResult = $null
        $automationResult = . (Join-Path $automationPath 'run.ps1')

        $automationStatus = "No update available"
        if ($automationResult) {
            $automationStatus = "Update available"
        }
    } catch {
        Write-Host "::Error::Error running automation: $($_.Exception.Message)"
        $automationStatus = "Failed"
    }
    finally {
        $automationRun = @{
            'Name' = $automationName
            'Result' = $automationResult
            'Status' = $automationStatus
        }
    }

    return $automationRun
}

function OpenPR {
    param(
        [Parameter(Mandatory=$true)]
        [array] $AvailableUpdates,
        [Parameter(Mandatory=$true)]
        [string] $Repository,
        [Parameter(Mandatory=$true)]
        [string] $TargetBranch,
        [Parameter(Mandatory=$true)]
        [string] $Actor
    )

    Write-Host "Opening PR for the following updates:"
    $AvailableUpdates | ForEach-Object {
        Write-Host "- $($_.Name): $($_.Result | Format-Table | Out-String)"
    }

    Set-GitConfig -Actor $Actor
    $branch = New-TopicBranch -Category "updates/$TargetBranch"

    # Open PR with a commit for each update
    $AvailableUpdates | ForEach-Object {
        $automationResult = $_.Result

        $commitMessage = "$($automationResult.Message)"
        $commitFiles = $automationResult.Files

        git add $commitFiles | Out-Null
        git commit -m $commitMessage | Out-Null
    }

    git push -u origin $branch | Out-Null

    return New-GitHubPullRequest -Repository $Repository -BranchName $branch -TargetBranch $TargetBranch
}

$automationsFolder = $PSScriptRoot
$automationNames = Get-ChildItem -Path $automationsFolder -Directory | ForEach-Object { $_.Name }

# Filter out the automations that are not included
if($Include) {
    $automationNames = $automationNames | Where-Object { $Include -contains $_ }
}

if(-not $automationNames) {
    throw "No automations match the include filter: $($Include -join ', ')" # Fail if no automations are found
}

$automationRuns = @()

foreach ($automationName in $automationNames) {
    Write-Host "::group::Running automation: $automationName"

    $automationStatus = RunAutomation -AutomationName $automationName
    Write-Host "Automation $($automationStatus.Name) completed. Status: $($automationStatus.Status)"

    $automationRuns += $automationStatus
    Write-Host "::endgroup::"
}

$availableUpdates = $automationRuns | Where-Object { $_.Status -eq "Update available" }
if($availableUpdates) { # Only open PR if there are updates
    Write-Host "::group::Opening PR for available updates"
    Import-Module $PSScriptRoot\AutomatedSubmission.psm1 -DisableNameChecking

    $prLink = OpenPR -AvailableUpdates $availableUpdates -Repository $Repository -TargetBranch $TargetBranch -Actor $Actor

    Write-Host "PR opened: $prLink"
    Write-Host "::endgroup::"
}

# Add GitHub job summary
$jobSummary = @"
Automation | Status | PR Link
--- | --- | ---
$($($automationRuns | ForEach-Object {
    $prLinkMD = '-'
    if($_.Status -eq "Update available") {
        $prLinkMD = "[$prLink]($prLink)"
    }
    return "$($_.Name) | $($_.Status) | $prLinkMD"
}) -join "`n")
"@

Add-Content -Path $ENV:GITHUB_STEP_SUMMARY -Value "$jobSummary" -Encoding utf8

# Fail if any automation failed
$failedAutomations = $automationRuns | Where-Object { $_.Status -eq "Failed" } | ForEach-Object { $_.Name }
if ($failedAutomations) {
    throw "The following automations failed: $($failedAutomations -join ', '). See logs above."
}