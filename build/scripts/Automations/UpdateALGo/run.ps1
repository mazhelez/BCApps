Import-Module $PSScriptRoot\..\..\EnlistmentHelperFunctions.psm1

$TargetBranch = Get-CurrentBranch
Write-Host "Updating AL-Go System Files by running the workflow Update AL-Go System Files on branch $TargetBranch"

$workflowName = " Update AL-Go System Files"
gh workflow run --repo microsoft/BCApps --ref $TargetBranch $workflowName

# The flow itself creates a PR, so no need to return anything here
