#InputRequired 'EXO:AdminAuditLogConfig'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Unified Audit Log'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Tenant Settings'
    'PassText'='Unified Audit Log is enabled'
    'FailRecommendation'='Enable the Unified Audit Log'
    'Importance'='The Unified Audit Log collects logs from most Office 365 services and provides one central place to correlate and pull logs from Office 365.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition
if ($null -eq $AdminAuditLogConfig.PSObject.Properties['UnifiedAuditLogIngestionEnabled']) {
    $TestDefinition.TestResult=$False
} Else {
    $TestDefinition.TestResult=$AdminAuditLogConfig.UnifiedAuditLogIngestionEnabled
}