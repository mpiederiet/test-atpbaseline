#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Anti-spoofing protection action'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Anti-spoofing protection action is configured to Move message to the recipients'' Junk Email folders in Anti-phishing policy'
    'FailRecommendation'='Configure Anti-spoofing protection action to Move message to the recipients'' Junk Email folders in Anti-phishing policy'
    'Importance'='When the sender email address is spoofed, the message appears to originate from someone or somewhere other than the actual source. With Standard security settings it is recommended to configure Anti-spoofing protection action to Move message to the recipients'' Junk Email folders in Office 365 Anti-phishing policies.'
    'Links'=@{'Configuring the anti-spoofing policy'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/learn-about-spoof-intelligence?view=o365-worldwide#configuring-the-anti-spoofing-policy';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AntiPhishPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'AntiPhish Policy' -NameProperty 'Name' -Property 'AuthenticationFailAction' -TestScript {($InputObject.Enabled -eq $True -or $InputObject.Identity -eq 'Office365 AntiPhish Default') -and $InputObject.$Property -eq 'MoveToJmf'}))
}

$TestDefinition.TestResult=$Return