Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$TargetBranch = Get-CurrentBranch
Write-Host "Updating AL-Go System Files by running the workflow Update AL-Go System Files on branch $TargetBranch"

$workflowName = " Update AL-Go System Files"
$workflowRun = gh workflow run --repo microsoft/BCApps --ref $TargetBranch $workflowName

if ($workflowRun) {
    return @{
        'Files' = @()
        'Message' = "Update AL-Go System Files workflow stared: $($workflowRun.html_url)"
    }
}
