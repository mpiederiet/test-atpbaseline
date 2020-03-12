#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Quarantine retention period'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Quarantine retention period is 30 days'
    'FailRecommendation'='Configure the Quarantine retention period to 30 days'
    'Importance'='You can view, release, download, delete and report false positive quarantined email messages or files captured by Advance Threat Protection (ATP) for SharePoint Online, OneDrive for Business, and Microsoft Teams in Office 365. Keep messages in the quarantine for 30 days to allow enough time for further investigation. This is the default value and also the maximum.'
    'Links'=@{'Manage quarantined messages and files as an administrator in Office 365'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/manage-quarantined-messages-and-files';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Fail if QuarantineRetentionPeriod is not set to 30
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'QuarantineRetentionPeriod' -TestScript {$InputObject.$Property -eq 30}))
}


$TestDefinition.TestResult=$Return