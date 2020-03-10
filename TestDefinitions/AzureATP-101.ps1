#InputRequired 'Azure:AzResource'
#Requires -Module 'Az.Security'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Microsoft Azure Cosmos DB Advanced Threat Protection'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Microsoft Azure Cosmos DB ATP'
    'PassText'='Azure ATP is enabled for all Cosmos DB instances.'
    'FailRecommendation'='Enable Azure ATP for your Cosmos DB instances.'
    'Importance'='Advanced Threat Protection for Azure Cosmos DB provides an additional layer of security intelligence that detects unusual and potentially harmful attempts to access or exploit Azure Cosmos DB accounts. This layer of protection allows you to address threats, even without being a security expert, and integrate them with central security monitoring systems. Security alerts are triggered when anomalies in activity occur. These security alerts are integrated with Azure Security Center, and are also sent via email to subscription administrators, with details of the suspicious activity and recommendations on how to investigate and remediate the threats.'
    'Links'=@{'Advanced Threat Protection for Azure Cosmos DB (Preview)'='https://docs.microsoft.com/en-us/azure/cosmos-db/cosmos-db-advanced-threat-protection';'Threat detection for data services in Azure Security Center'='https://docs.microsoft.com/en-us/azure/security-center/security-center-alerts-data-services'}
}
Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

Function Get-AzureCosmosDB ($Subscription) {
    Return ($AzResource[$Subscription] | Where-Object {$_.ResourceType -eq 'Microsoft.DocumentDb/databaseAccounts'})
}

ForEach ($Subscription in $Script:SubscriptionsToCheck) {
    $AzContext=Get-AzContext
    if ($AzContext.Subscription -ne $Subscription.SubscriptionId) {
        Set-AzContext -SubscriptionId $Subscription.SubscriptionId
    }
    $CosmosDBs=Get-AzureCosmosDB -Subscription ($Subscription.Name)

    ForEach($CosmosDB in $CosmosDBs) {
        $AzureATP=Get-AzSecurityAdvancedThreatProtection -ResourceId $CosmosDB.ResourceId -ErrorAction SilentlyContinue
        if ($null -ne $AzureATP -and $AzureATP.IsEnabled) {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure Cosmos DB'="$($Subscription.Name)/$($CosmosDB.ResourceGroupName)/$($CosmosDB.Name)"
                'ATP'='Enabled'
                'Result'='Pass'
            })
       } Else {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure Cosmos DB'="$($Subscription.Name)/$($CosmosDB.ResourceGroupName)/$($CosmosDB.Name)"
                'ATP'='Disabled'
                'Result'='Fail'
            })
        }
    }   
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Azure Cosmos DB'='No Azure Cosmos DB instances found'
        'ATP'='No Azure Cosmos DB instances found'
        'Result'='Pass'
    })
}

$TestDefinition.TestResult=$Return