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
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $MalwareFilterPolicy) {
    # Fail if NotifyOutboundSpam is not set to true in the policy
    if($Policy.EnableFileFilter -eq $false -or @($Policy.FileTypes).Count -eq 0) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Malware Policy'=$($Policy.Name)
            'Setting'='EnableFilterFilter is false and/or FileTypes count is zero'
            'Result'='Fail'
        })
    } else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Malware Policy'=$($Policy.Name)
            'Setting'="EnableFileFilter: $($Policy.EnableFileFilter). FileTypes Count: $(($Policy.FileTypes).Count)"
            'Result'='Pass'
        })
    }
}

$TestDefinition.TestResult=$Return