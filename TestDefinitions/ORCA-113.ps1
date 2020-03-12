#InputRequired 'EXO:AtpPolicyForO365','EXO:SafeLinksPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Do not let users click through safe links'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='DoNotAllowClickThrough is enabled in Safe Links policies'
    'FailRecommendation'='Do not let users click through safe links to original URL'
    'Importance'='Office 365 ATP Safe Links can help protect your organization by providing time-of-click verification of  web addresses (URLs) in email messages and Office documents. It is possible to allow users click through Safe Links to the original URL. It is recommended to configure Safe Links policies to not let users click through safe links.'
    'Links'=@{'Set up Office 365 ATP Safe Links policies'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/set-up-atp-safe-links-policies#step-4-learn-about-atp-safe-links-policy-options';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AtpPolicyForO365) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'ATP Policy' -NameProperty 'Name' -Property 'AllowClickThrough' -TestScript {$InputObject.$Property -eq $False}))
}

ForEach($Policy in ($SafeLinksPolicy | Where-Object {$_ -and $_.IsEnabled})) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'SafeLinks Policy' -NameProperty 'Name' -Property 'DoNotAllowClickThrough' -TestScript {$InputObject.$Property -eq $True}))
}

$TestDefinition.TestResult=$Return