#InputRequired 'EXO:SafeLinksPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Safe Links Tracking in Email messages'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Links Policies are tracking when user clicks on safe links in email messages'
    'FailRecommendation'='Enable tracking of user clicks in Safe Links Policies'
    'Importance'='When these options are configured, click data for URLs in emails is stored by Safe Links. This information can help dealing with phishing, suspicious email messages and URLs.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $SafeLinksPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'SafeLinks Policy' -NameProperty 'Name' -Property 'DoNotTrackUserClicks' -TestScript {$InputObject.$Property -eq $True}))
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'SafeLinks Policy'='ATP SafeLinks Policies'
        'Setting'='No SafeLinks Policies found'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return