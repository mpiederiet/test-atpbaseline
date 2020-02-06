#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Supported filter policy action'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Zero Hour Autopurge'
    'PassText'='Supported filter policy action used'
    'FailRecommendation'='Change filter policy action to support Zero Hour Auto Purge'
    'Importance'='Zero Hour Autopurge can assist removing false-negatives post detection from mailboxes. It requires a supported action in the spam filter policy.'
    'Links'=@{'Zero-hour auto purge - protection against spam and malware'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/zero-hour-auto-purge'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Check requirement of Spam ZAP - MoveToJmf, redirect, delete, quarantine
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'SpamAction' -TestScript {$InputObject.$Property -in 'MoveToJmf','Redirect','Delete','Quarantine'}))
    # Check requirement of Phish ZAP - MoveToJmf, redirect, delete, quarantine
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'PhishSpamAction' -TestScript {$InputObject.$Property -in 'MoveToJmf','Redirect','Delete','Quarantine'}))
}

$TestDefinition.TestResult=$Return