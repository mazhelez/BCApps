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

function OpenPR($AvailableUpdates, $Repository, $TargetBranch, $Actor) {
    Import-Module $PSScriptRoot\AutomatedSubmission.psm1


    Write-Host "Opening PR for the following updates:"
    $AvailableUpdates | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Result)"
    }

    Set-GitConfig -Actor $Actor
    $branch = New-TopicBranch -Category 'updates'

    # Open PR with a commit for each update
    $AvailableUpdates | ForEach-Object {
        $automationName = $_.Name
        $automationResult = $_.Result

        $commitMessage = "$($automationResult.Message)"
        $commitFiles = $automationResult.Files

        git add $commitFiles
        git commit -m $commitMessage
    }

    git push -u origin $branch

    New-GitHubPullRequest -Repository $Repository -BranchName $branch -TargetBranch $TargetBranch -Title "Automated updates" -Body "Automated updates"

}

$automationsFolder = $PSScriptRoot
$automationsPaths = Get-ChildItem -Path $automationsFolder -Directory -Filter $Filter

# Filter out the automations that are not included
if($Include) {
    $automationsPaths = $automationsPaths | Where-Object { $Include -contains $_.Name }
}

$availableUpdates = @()
$failedAutomations = @()

foreach ($automationPath in $automationsPaths) {
    $automationName = $automationPath.Name
    Write-Host "Running automation $automationName"

    try {
        $automationResult = . (Join-Path $automationPath.FullName 'run.ps1') -TargetBranch $TargetBranch
    } catch {
        Write-Host "Error running automation: $($_.Exception.Message)" -ForegroundColor Red
        $failedAutomations += @($automationName)
    }

    if ($automationResult) {
        $availableUpdates += @{
            'Name' = $automationName
            'Result' = $automationResult
        }
    }

    Write-Host "Automation $automationName completed"
}

if($availableUpdates.Count -eq 0) {
    Write-Host "No available updates"
    return
}

OpenPR -AvailableUpdates $availableUpdates -Repository $Repository -TargetBranch $TargetBranch -Actor $Actor

if ($failedAutomations) {
    throw "The following automantions failed: $($failedAutomations -join ', '). See logs above for details"
}