#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Unauthenticated Sender (tagging)'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Anti-phishing policy exists and EnableUnauthenticatedSender is true'
    'FailRecommendation'='Enable unauthenticated sender tagging in Anti-phishing policy'
    'Importance'='When the sender email address is spoofed, the message appears to originate from someone or somewhere other than the actual source. It is recommended to enable unauthenticated sender tagging in Office 365 Anti-phishing policies. The feature apply a ''?'' symbol in Outlook''s sender card if the sender fails authentication checks.'
    'Links'=@{'Unverified Sender'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/unverified-sender-feature';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AntiPhishPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'AntiPhish Policy' -NameProperty 'Name' -Property 'EnableUnauthenticatedSender' -TestScript {($InputObject.Enabled -eq $True -or $InputObject.Identity -eq 'Office365 AntiPhish Default') -and $InputObject.$Property -eq $True}))
}

$TestDefinition.TestResult=$Return