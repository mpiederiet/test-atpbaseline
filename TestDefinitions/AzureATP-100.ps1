#InputRequired 'Azure:AzResource'
#Requires -Module 'Az.Security'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Microsoft Azure Storage Advanced Threat Protection'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Microsoft Azure Storage ATP'
    'PassText'='Azure ATP is enabled for all storage blobs.'
    'FailRecommendation'='Enable Azure ATP for your storage blobs.'
    'Importance'='Advanced threat protection for Azure Storage provides an additional layer of security intelligence that detects unusual and potentially harmful attempts to access or exploit storage accounts. Security alerts are triggered in Azure Security Center when anomalies in activity occur and are also sent via email to subscription administrators, with details of suspicious activity and recommendations on how to investigate and remediate threats.'
    'Links'=@{'Security recommendations for Blob storage'='https://docs.microsoft.com/en-us/azure/storage/blobs/security-recommendations';'Configure advanced threat protection for Azure Storage'='https://docs.microsoft.com/en-us/azure/storage/common/storage-advanced-threat-protection';'Threat detection for data services in Azure Security Center'='https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-data-services'}
}
Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

Function Get-AzureStorageBlobs {
    Return ($AzResource | Where-Object {$_.ResourceType -eq 'Microsoft.Storage/storageAccounts'})
}

ForEach ($Subscription in $Script:SubscriptionsToCheck) {
    $AzContext=Get-AzContext
    if ($AzContext.Subscription -ne $Subscription.SubscriptionId) {
        Set-AzContext -SubscriptionId $Subscription.SubscriptionId
    }
    $AzureStorageBlobs=Get-AzureStorageBlobs

    ForEach($StorageBlob in $AzureStorageBlobs) {
        $AzureATP=Get-AzSecurityAdvancedThreatProtection -ResourceId $StorageBlob.ResourceId -ErrorAction SilentlyContinue
        if ($null -ne $AzureATP -and $AzureATP.IsEnabled) {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure Storage Blob'="$($Subscription.Name)/$($StorageBlob.ResourceGroupName)/$($StorageBlob.Name)"
                'ATP'='Enabled'
                'Result'='Pass'
            })
       } Else {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure Storage Blob'="$($Subscription.Name)/$($StorageBlob.ResourceGroupName)/$($StorageBlob.Name)"
                'ATP'='Disabled'
                'Result'='Fail'
            })
        }
    }   
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Azure Storage Blob'='No Azure storage blobs found'
        'ATP'='No Azure storage blobs found'
        'Result'='Pass'
    })
}

$TestDefinition.TestResult=$Return