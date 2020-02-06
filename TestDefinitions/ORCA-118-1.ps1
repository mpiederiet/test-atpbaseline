#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Domain Whitelisting'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Domains are not being whitelisted in an unsafe manner'
    'FailRecommendation'='Remove whitelisting on domains'
    'Importance'='Emails coming from whitelisted domains bypass several layers of protection within Exchange Online Protection. If domains are whitelisted, they are open to being spoofed from malicious actors.'
    'Links'=@{'Use Anti-Spam Policy Sender/Domain Allow lists'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365#use-anti-spam-policy-senderdomain-allow-lists'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Fail if AllowedSenderDomains is not null
    If(($Policy.AllowedSenderDomains).Count -gt 0) {
        ForEach($Domain in $Policy.AllowedSenderDomains) {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Whitelisted Domain'=$Domain.Domain
                'Result'='Fail'
            })
        }
    } else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Content Filter Policy'=$Policy.Name
            'Whitelisted Domain'='0 Allowed Sender Domains'
            'Result'='Pass'
        })
    }
}

$TestDefinition.TestResult=$Return