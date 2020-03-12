#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Allowed Senders'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Senders are not being whitelisted in an unsafe manner'
    'FailRecommendation'='Remove whitelisting on senders'
    'Importance'='Emails coming from whitelisted senders bypass several layers of protection within Exchange Online Protection. If senders are whitelisted, they are open to being spoofed from malicious actors.'
    'Links'=@{'Use Anti-Spam Policy Sender/Domain Allow lists'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365#use-anti-spam-policy-senderdomain-allow-lists';'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Fail if AllowedSenderDomains is not null
    If(($Policy.AllowedSenders).Count -gt 0) {
        ForEach($Sender in $Policy.AllowedSenders) {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Allowed sender'=$Sender
                'Result'='Fail'
            })
        }
    } else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Content Filter Policy'=$Policy.Name
            'Allowed sender'='0 Allowed Senders'
            'Result'='Pass'
        })
    }}


$TestDefinition.TestResult=$Return