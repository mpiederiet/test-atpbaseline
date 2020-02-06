#InputRequired 'EXO:HostedConnectionFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='IP Allow Lists'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='No IP Allow Lists have been configured'
    'FailRecommendation'='Remove IP addresses from IP allow list'
    'Importance'='IP addresses containted in the IP allow list are able to bypass spam, phishing and spoofing checks, potentially resulting in more spam. Ensure that the IP list is kept to a minimum.'
    'Links'=@{'Use Anti-Spam Policy IP Allow lists'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365#use-anti-spam-policy-ip-allow-lists'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedConnectionFilterPolicy) {
    if ($Policy.IPAllowList.Count -eq 0) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Content Filter Policy'=$Policy.Name
            'Allowed IP'="IP Entries: $($Policy.IPAllowList.Count)"
            'Result'='Pass'
        })
    } Else {
        ForEach ($IPAddr in $Policy.IPAllowList) {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Allowed IP'=$IPAddr
                'Result'='Fail'
            })
        }
    }
}

$TestDefinition.TestResult=$Return