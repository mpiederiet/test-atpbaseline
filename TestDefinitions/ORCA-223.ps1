#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='User Impersonation Action'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='User impersonation action is set to move to Quarantine'
    'FailRecommendation'='Configure user impersonation action to Quarantine'
    'Importance'='User impersonation protection can detect spoofing of your sensitive users. Move messages that are caught using user impersonation detection to Quarantine.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in ($AntiPhishPolicy | Where-Object {$_.Enabled -eq $True})) {
    If($Policy.EnableTargetedUserProtection -eq $False) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='EnableTargetedUserProtection'
            'Value'=$Policy.EnableTargetedUserProtection
            'Result'='Fail'
        })
    } Else {
        # Check for action being MoveToJmf
        If($Policy.TargetedUserProtectionAction -eq 'Quarantine') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'AntiPhish Policy'=$($Policy.Name)
                'Setting'='TargetedUserProtectionAction'
                'Value'=$Policy.TargetedUserProtectionAction
                'Result'='Pass'
            })
        } Else {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'AntiPhish Policy'=$($Policy.Name)
                'Setting'='TargetedUserProtectionAction'
                'Value'=$Policy.TargetedUserProtectionAction
                'Result'='Fail'
            })
        }
    }
}

If($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'AntiPhish Policy'='AntiPhishing Policies'
        'Setting'='No Enabled AntiPhish Policy'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return