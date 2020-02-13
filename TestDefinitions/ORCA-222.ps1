#InputRequired 'EXO:AntiPhishPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Domain Impersonation Action'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Domain Impersonation action is set to move to Quarantine'
    'FailRecommendation'='Configure domain impersonation action to Quarantine'
    'Importance'='Domain Impersonation can detect impersonation attempts against your domains or domains that look very similiar to your domains. Move messages that are caught using this impersonation protection to Quarantine.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in ($AntiPhishPolicy | Where-Object {$_.Enabled -eq $True})) {
    If($Policy.EnableTargetedDomainsProtection -eq $False -and $Policy.EnableOrganizationDomainsProtection -eq $False) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='EnableOrganizationDomainsProtection'
            'Value'=$Policy.EnableOrganizationDomainsProtection
            'Result'='Fail'
        })
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='EnableTargetedDomainsProtection'
            'Value'=$Policy.EnableTargetedDomainsProtection
            'Result'='Fail'
        })
    }
    If($Policy.EnableTargetedDomainsProtection -eq $True) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='EnableTargetedDomainsProtection'
            'Value'=$Policy.EnableTargetedDomainsProtection
            'Result'='Pass'
        })
    }
    If($Policy.EnableOrganizationDomainsProtection -eq $True) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='EnableOrganizationDomainsProtection'
            'Value'=$Policy.EnableOrganizationDomainsProtection
            'Result'='Pass'
        })
    }

    If($Policy.TargetedDomainProtectionAction -ne 'Quarantine') {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='TargetedDomainProtectionAction'
            'Value'=$Policy.TargetedDomainProtectionAction
            'Result'='Fail'
        })
    } Else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'AntiPhish Policy'=$($Policy.Name)
            'Setting'='TargetedDomainProtectionAction'
            'Value'=$Policy.TargetedDomainProtectionAction
            'Result'='Pass'
        })
    }
}

If($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'AntiPhish Policy'='AntiPhishing Policies'
        'Setting'="No Enabled AntiPhish Policy"
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return