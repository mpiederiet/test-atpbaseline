#InputRequired 'EXO:SafeLinksPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Intra-organization Safe Links'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Links is enabled intra-organization'
    'FailRecommendation'='Enable Safe Links between internal users'
    'Importance'='Phishing attacks are not limited from external users. Commonly, when one user is compromised, that user can be used in a process of lateral movement between different accounts in your organization. Configuring Safe Links so that internal messages are also re-written can assist with lateral movement using phishing.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $SafeLinksPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'SafeLinks Policy' -NameProperty 'Name' -Property 'EnableForInternalSenders' -TestScript {$InputObject.$Property -eq $True}))
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'SafeLinks Policy'='ATP SafeLinks Policies'
        'Setting'='No SafeLinks Policies found'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return