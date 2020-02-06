#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Mailbox Intelligence Action'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Your policy is configured to notify users with a tip.'
    'FailRecommendation'='Enable tips so that users can receive visible indication on incoming messages.'
    'Importance'='Mailbox Intelligence checks can provide your users with intelligence on suspicious incoming emails that appear to be from users that they normally communicate with based on their graph.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in ($AntiPhishPolicy | Where-Object {$_.Enabled -eq $True})) {
    #  Determine if tips for user impersonation is on
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'AntiPhish Policy' -NameProperty 'Name' -Property 'EnableSimilarUsersSafetyTips' -TestScript {$InputObject.$Property -eq $True}))
}

If($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'AntiPhish Policy'='AntiPhishing Policies'
        'Setting'="No Enabled AntiPhish Policy"
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return