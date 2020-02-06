#InputRequired 'EXO:AtpPolicyForO365'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Office Enablement'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Links is enabled for Office ProPlus, Office for iOS and Android'
    'FailRecommendation'='Enable Safe Links for Office ProPlus, Office for iOS and Android in the O365 ATP Policy'
    'Importance'='Phishing attacks are not limited to email messages. Malicious URLs can be delivered using Office documents as well. Configuring Office 365 ATP Safe Links for Office ProPlus,  Office for iOS and Android can help combat against these attacks via providing time-of-click verification of web addresses (URLs) in Office documents.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AtpPolicyForO365) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'ATP Policy' -NameProperty 'Name' -Property 'EnableSafeLinksForClients' -TestScript {$InputObject.$Property -eq $True}))
}

$TestDefinition.TestResult=$Return