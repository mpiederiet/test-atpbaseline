#InputRequired 'EXO:AtpPolicyForO365'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Safe Attachments SharePoint and Teams'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Attachments is enabled for SharePoint and Teams'
    'FailRecommendation'='Enable Safe Attachments for SharePoint and Teams'
    'Importance'='Safe Attachments assists scanning for zero day malware by using behavioural analysis and sandboxing, supplimenting signature definitions.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AtpPolicyForO365) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'ATP Policy' -NameProperty 'Name' -Property 'EnableATPForSPOTeamsODB' -TestScript {$InputObject.$Property -eq $True}))
}

$TestDefinition.TestResult=$Return