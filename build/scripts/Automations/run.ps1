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
        Write-Host "  - $($_.Name): $($_.Result)"
    }

    Set-GitConfig -Actor $Actor
    $branch = New-TopicBranch -Category 'updates'

    # Open PR with a commit for each update
    $AvailableUpdates | ForEach-Object {
        $automationResult = $_.Result

        $commitMessage = "$($automationResult.Message)"
        $commitFiles = $automationResult.Files

        git add $commitFiles
        git commit -m $commitMessage
    }

    git push -u origin $branch

    return New-GitHubPullRequest -Repository $Repository -BranchName $branch -TargetBranch $TargetBranch
}

$automationsFolder = $PSScriptRoot
$automationsPaths = Get-ChildItem -Path $automationsFolder -Directory

# Filter out the automations that are not included
if($Include) {
    $automationsPaths = $automationsPaths | Where-Object { $Include -contains $_.Name }
}

Write-Host "::group::Running automation(s) $(($automationsPaths | ForEach-Object { $_.Name }) -join ', ')"
$availableUpdates = @()
$failedAutomations = @()
$succeededAutomations = @()

foreach ($automationPath in $automationsPaths) {
    $automationName = $automationPath.Name
    Write-Host "Running automation $automationName"

    try {
        $automationResult = . (Join-Path $automationPath.FullName 'run.ps1')
    } catch {
        Write-Host "::error Error running automation: $($_.Exception.Message)"
        $failedAutomations += @($automationName)
        continue
    }

    if ($automationResult) {
        $availableUpdates += @{
            'Name' = $automationName
            'Result' = $automationResult
        }
    }
    $succeededAutomations += @($automationName)
    Write-Host "Automation $automationName completed"
}

if($availableUpdates) {
    Write-Host "::group::Opening PR for available updates"
    Import-Module $PSScriptRoot\AutomatedSubmission.psm1 -DisableNameChecking

    $prLink = OpenPR -AvailableUpdates $availableUpdates -Repository $Repository -TargetBranch $TargetBranch -Actor $Actor
    Write-Host "::endgroup::"
}

# Add GitHub job summary
$jobSummary = @"
Automation | Status | PR
--- | --- | ---
$($failedAutomations | ForEach-Object { $automation = $_; "$($automation) | Failed | -" })
$($succeededAutomations | ForEach-Object { $automation = $_; "$($automation) | Succeeded | $prLink" })
"@

Add-Content -Path $ENV:GITHUB_STEP_SUMMARY -value "$jobSummary" -Encoding utf8

if ($failedAutomations) {
    throw "The following automantions failed: $($failedAutomations -join ', '). See logs above for details"
}