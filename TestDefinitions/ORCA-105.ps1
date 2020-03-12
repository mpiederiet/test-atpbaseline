#InputRequired 'EXO:SafeLinksPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Safe Links Synchronous URL detonation'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Links Synchronous URL detonation is enabled'
    'FailRecommendation'='Enable Safe Links Synchronous URL detonation'
    'Importance'='When the ''Wait for URL scanning to complete before delivering the message'' option is configured, messages that contain URLs to be scanned will be held until the URLs finish scanning and are confirmed to be safe before the messages are delivered.'
    'Links'=@{'Set up Office 365 ATP Safe Links policies'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/set-up-atp-safe-links-policies#step-4-learn-about-atp-safe-links-policy-options';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in ($SafeLinksPolicy | Where-Object {$_ -and $_.IsEnabled})) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'SafeLinks Policy' -NameProperty 'Name' -Property 'DeliverMessageAfterScan' -TestScript {$InputObject.$Property -eq $True}))
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'SafeLinks Policy' -NameProperty 'Name' -Property 'ScanUrls' -TestScript {$InputObject.$Property -eq $True}))
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'SafeLinks Policy'='ATP SafeLinks Policies'
        'Setting'='No SafeLinks Policies found'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return