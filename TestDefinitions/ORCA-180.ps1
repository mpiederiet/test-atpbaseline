#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Anti-spoofing protection'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Anti-phishing policy exists and EnableAntiSpoofEnforcement is true'
    'FailRecommendation'='Enable anti-spoofing protection in Anti-phishing policy'
    'Importance'='When the sender email address is spoofed, the message appears to originate from someone or somewhere other than the actual source. Anti-spoofing protection examines forgery of the ''From: header'' which is the one that shows up in an email client like Outlook. It is recommended to enable anti-spoofing protection in Office 365 Anti-phishing policies.'
    'Links'=@{'Anti-spoofing protection in Office 365'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-spoofing-protection';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#office-365-advanced-threat-protection-security'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in ($AntiPhishPolicy | Where-Object {$_.Enabled -eq $True})) {
    #  Determine if tips for user impersonation is on
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'AntiPhish Policy' -NameProperty 'Name' -Property 'EnableAntiSpoofEnforcement' -TestScript {$InputObject.$Property -eq $True}))
}

If($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'AntiPhish Policy'='AntiPhishing Policies'
        'Setting'="No Enabled AntiPhish Policy"
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return