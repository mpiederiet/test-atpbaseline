#InputRequired 'EXO:MalwareFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='External Sender Notifications'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Malware Filter Policy'
    'PassText'='External Sender notifications are disabled'
    'FailRecommendation'='Disable notifying external senders of malware detection'
    'Importance'='Notifying external senders about malware detected in email messages could have negative impact. An adversary may use this information to verify effectiveness of malware detection.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop';'Configure anti-malware policies'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-malware-policies'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $MalwareFilterPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Malware Policy' -NameProperty 'Name' -Property 'EnableExternalSenderNotifications' -TestScript {$InputObject.$Property -eq $False}))
}

$TestDefinition.TestResult=$Return