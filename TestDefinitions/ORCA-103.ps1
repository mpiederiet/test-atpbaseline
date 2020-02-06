#InputRequired 'EXO:HostedOutboundSpamFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Outbound spam filter policy settings'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Outbound spam filter policy settings configured'
    'FailRecommendation'='Set RecipientLimitExternalPerHour to 500, RecipientLimitInternalPerHour to 1000, and ActionWhenThresholdReached to block.'
    'Importance'='Configure the maximum number of recipients that a user can send to, per hour for internal (RecipientLimitInternalPerHour) and external recipients (RecipientLimitExternalPerHour) and maximum number per day for outbound email. It is common, after an account compromise incident, for an attacker to use the account to generate spam and phish. Configuring the recommended values can reduce the impact, but also allows you to receive notifications when these thresholds have been reached.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedOutboundSpamFilterPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Outbound Spam Policy' -NameProperty 'Name' -Property 'RecipientLimitExternalPerHour' -TestScript {$InputObject.$Property -eq 500}))
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Outbound Spam Policy' -NameProperty 'Name' -Property 'RecipientLimitInternalPerHour' -TestScript {$InputObject.$Property -eq 1000}))
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Outbound Spam Policy' -NameProperty 'Name' -Property 'RecipientLimitPerDay' -TestScript {$InputObject.$Property -eq 1000}))
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Outbound Spam Policy' -NameProperty 'Name' -Property 'ActionWhenThresholdReached' -TestScript {$InputObject.$Property -like 'BlockUser'}))
}

$TestDefinition.TestResult=$Return