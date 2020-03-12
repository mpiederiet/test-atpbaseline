#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='End-user Spam notifications'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='End-user Spam notification is enabled and the frequency is set to 3 days'
    'FailRecommendation'='Enable End-user Spam notification and set the frequency to 3 days'
    'Importance'='Enable End-user Spam notifications to let users manage their own spam-quarantined messages (Release, Block sender, Review). End-user spam notifications contain a list of all spam-quarantined messages that the end-user has received during a time period.'
    'Links'=@{'Configure end-user spam notifications in Exchange Online'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-end-user-spam-notifications-in-exchange-online';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Fail if EnableEndUserSpamNotifications is not set to $True
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'EnableEndUserSpamNotifications' -TestScript {$InputObject.$Property -eq $true}))
    # Fail if EndUserSpamNotificationFrequency is not set to 3
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'EndUserSpamNotificationFrequency' -TestScript {$InputObject.$Property -eq 3}))
}


$TestDefinition.TestResult=$Return