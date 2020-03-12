#InputRequired 'EXO:MalwareFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Common Attachment Type Filter'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Malware Filter Policy'
    'PassText'='Common attachment type filter is enabled'
    'FailRecommendation'='Enable common attachment type filter'
    'Importance'='The common attachment type filter can block file types that commonly contain malware, including in internal emails.'
    'Links'=@{'Configure anti-malware policies'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/configure-anti-malware-policies';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $MalwareFilterPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Malware Policy' -NameProperty 'Name' -Property 'EnableFileFilter' -TestScript {$InputObject.$Property -eq $True}))
    if(($Policy.FileTypes).Count -eq 0) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Malware Policy'=$($Policy.Name)
            'Setting'='FileTypes'
            'Value'=0
            'Result'='Fail'
        })
    } else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Malware Policy'=$($Policy.Name)
            'Setting'='FileTypes'
            'Value'=($Policy.FileTypes).Count
            'Result'='Pass'
        })
    }
}

$TestDefinition.TestResult=$Return