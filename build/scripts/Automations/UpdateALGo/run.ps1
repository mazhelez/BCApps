param (
    [Parameter(Mandatory=$true)]
    [string] $Repository
)

Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$TargetBranch = Get-CurrentBranch
Write-Host "Running the workflow Update AL-Go System Files on branch $TargetBranch"

$workflowName = " Update AL-Go System Files"
$workflowRun = gh workflow run --repo $Repository --ref $TargetBranch $workflowName

if ($workflowRun) {
    return @{
        'Files' = @()
        'Message' = "Update AL-Go System Files workflow stared: $($workflowRun.html_url)"
    }
}
