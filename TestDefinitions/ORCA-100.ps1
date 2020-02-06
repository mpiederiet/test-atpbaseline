#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Bulk Complaint Level'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Bulk Complaint Level threshold is set between 4 and 6'
    'FailRecommendation'='Bulk Complaint Level threshold is between 4 and 6'
    'Importance'='The differentiation between bulk and spam can sometimes be subjective. The bulk complaint level is based on the number of complaints from the sender. Decreasing the threshold can decrease the amount of perceived spam received, however, too low may be considered too strict.'
    'Links'=@{
        'Bulk Complaint Level values'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/bulk-complaint-level-values'
        'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop'
    }
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    $Null=$Return.Add((New-ReturnObject -Inputobject $Policy -ObjectName 'Content Filter Policy' -NameProperty 'Name' -Property 'BulkThreshold' -TestScript {$InputObject.$Property -ge 4 -and $InputObject.$Property -le 6}))
}

$TestDefinition.TestResult=$Return