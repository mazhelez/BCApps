param (
    [Parameter(Mandatory=$true)]
    [string] $Repository
)

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$TargetBranch = Get-CurrentBranch
Write-Host "Running the workflow Update AL-Go System Files on branch $TargetBranch"

$workflowName = " Update AL-Go System Files"
gh workflow run --repo $Repository --ref $TargetBranch $workflowName

# Get the workflow run URL to display in the message
$now = Get-Date

while((Get-Date) -lt $now.AddMinutes(1)) {
    $workflowRun = gh api "/repos/$Repository/actions/runs" --jq ".workflow_runs[] | select(.name == \"$workflowName\" and .head_branch == \"$TargetBranch\")" | ConvertFrom-Json | Select-Object -First 1

    if ($workflowRun) {
        break
    }

    Start-Sleep -Seconds 5
}

if ($workflowRun) {
    return @{
        'Files' = @()
        'Message' = "Update AL-Go System Files workflow stared: $($workflowRun.html_url)"
    }
}
