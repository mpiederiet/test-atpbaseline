#Requires -Module 'Az.Accounts'
# Suppress breaking changes
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'
function Get-AzureConnectionStatus {
    Return ($null -ne (Get-AzContext))
}

function Invoke-AzureConnection {
    if($null -eq (Get-AzContext)) {
        Connect-AzAccount
    }

    if($null -eq (Get-AzContext)) {
        Write-Error 'Failed to connect to Azure! No Azure resources will be loaded'
        return
    }
}

Function Invoke-AzureCommands([string[]]$CommandsToPreload) {
    Write-Verbose "$(Get-Date) Caching Azure configuration information for $($CommandsToPreload.Count) cmdlets"
    ForEach ($CmdletToLoad in $CommandsToPreload) {
        Write-Verbose "$(Get-Date) Invoking Get-$CmdletToLoad"
        Remove-Variable -Scope 'Script' -Name $CmdletToLoad -ErrorAction SilentlyContinue
        New-Variable -Scope 'Script' -Name $CmdletToLoad -Value (New-Object System.Collections.ArrayList)
        ForEach ($Subscription in $Script:SubscriptionsToCheck) {
            $AzContext=Get-AzContext
            if ($AzContext.Subscription -ne $Subscription.SubscriptionId) {
                Set-AzContext -SubscriptionId $Subscription.SubscriptionId
            }
            (Get-Variable -Scope 'Script' -Name $CmdletToLoad).Value.AddRange(@(Invoke-Expression "Get-$CmdletToLoad"))
        }
        $Null=$script:PreloadedCommands.Add($CmdletToLoad)
    }
}

# Connect to MS Azure
If ((Get-AzureConnectionStatus) -eq $False) {
    Invoke-AzureConnection
}
$Script:AzureSubscriptions=Get-AzSubscription
$Script:AzContext=Get-AzContext
if ($null -eq $Script:AzureSubscriptions) {
    Write-Warning "No Azure subscriptions found for $(($Script:AzContext).Account)"
    $Script:ActiveAzureSubscriptions=@()
    $Script:CurrentAzureSubscription=$null
    $Script:SubscriptionsToCheck=@()
} Else {
    $Script:ActiveAzureSubscriptions=$AzureSubscriptions|Where-Object{$_.State -eq 'Enabled'}
    $Script:CurrentAzureSubscription=$AzureSubscriptions|Where-Object{$_.SubscriptionId -eq (($AzContext).Subscription)}
    # Show a dialog to select the Azure subscriptions to check
    $SelectedSubscriptions=New-ListboxDialog -FormTitle 'Please select the Azure subscription(s) to be checked' -ListItems ($ActiveAzureSubscriptions|Select-Object -Expand Name) -Explanation 'Please select the Azure subscription(s) to be checked' -DefaultItem $CurrentAzureSubscription.Name
    $Script:SubscriptionsToCheck=$AzureSubscriptions|Where-Object {$_.Name -in $SelectedSubscriptions}
}