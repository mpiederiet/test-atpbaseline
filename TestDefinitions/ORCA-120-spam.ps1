#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Zero Hour Autopurge Enabled for Spam'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Zero Hour Autopurge'
    'PassText'='Zero Hour Autopurge is Enabled'
    'FailRecommendation'='Enable Zero Hour Autopurge'
    'Importance'='Zero Hour Autopurge can assist removing false-negatives post detection from mailboxes. By default, it is enabled.'
    'Links'=@{'Zero-hour auto purge - protection against spam and malware'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/zero-hour-auto-purge';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'SpamZapEnabled' -TestScript {$InputObject.$Property -eq $True}))
}

$TestDefinition.TestResult=$Return