#InputRequired 'Azure:AzResource'
#Requires -Module 'Az.sql'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Microsoft Azure SQL DB Advanced Threat Protection'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Microsoft Azure SQL DB ATP'
    'PassText'='Azure ATP is enabled for all SQL DB instances.'
    'FailRecommendation'='Enable Azure ATP for your SQL DB instances.'
    'Importance'='Advanced Threat Protection for Azure SQL Database and SQL Data Warehouse detects anomalous activities indicating unusual and potentially harmful attempts to access or exploit databases. Advanced Threat Protection is part of the Advanced data security (ADS) offering, which is a unified package for advanced SQL security capabilities. Advanced Threat Protection can be accessed and managed via the central SQL ADS portal.'
    'Links'=@{'Advanced Threat Protection for Azure SQL Database'='https://docs.microsoft.com/en-us/azure/sql-database/sql-database-threat-detection-overview'}
}
Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

Function Get-AzureSQLDB {
    Return ($AzResource | Where-Object {$_.ResourceType -eq 'Microsoft.Sql/servers/databases'})
}

ForEach ($Subscription in $Script:SubscriptionsToCheck) {
    $AzContext=Get-AzContext
    if ($AzContext.Subscription -ne $Subscription.SubscriptionId) {
        Set-AzContext -SubscriptionId $Subscription.SubscriptionId
    }
    $SQLDBs=Get-AzureSQLDB

    ForEach($SQLDB in $SQLDBs) {
        $DatabaseName=($SQLDB.Name.Split('/'))[1]
        $ServerName=($SQLDB.Name.Split('/'))[0]
        $AzureATP=Get-AzSqlDatabaseAdvancedThreatProtectionSetting -DatabaseName $DatabaseName -servername $ServerName -ResourceGroupName $SQLDB.ResourceGroupName
        
        if ($null -ne $AzureATP -and $AzureATP.ThreatDetectionState -eq 'Enabled') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure SQL DB'="$($Subscription.Name)/$($SQLDB.ResourceGroupName)/$($SQLDB.Name)"
                'ATP'='Enabled'
                'Result'='Pass'
            })
       } Else {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Azure SQL DB'="$($Subscription.Name)/$($SQLDB.ResourceGroupName)/$($SQLDB.Name)"
                'ATP'='Disabled'
                'Result'='Fail'
            })
        }
    }   
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Azure SQL DB'='No Azure SQL DB instances found'
        'ATP'='No Azure SQL DB instances found'
        'Result'='Pass'
    })
}

$TestDefinition.TestResult=$Return