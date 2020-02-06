#InputRequired 'EXO:TransportRule'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Safe Attachment Whitelisting'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Attachments is not bypassed'
    'FailRecommendation'='Remove mail flow rules which bypass Safe Attachments'
    'Importance'='Office 365 ATP Safe Attachments assists scanning for zero day malware by using behavioural analysis and sandboxing, supplementing signature definitions. The protection can be bypassed using mail flow rules which set the X-MS-Exchange-Organization-SkipSafeAttachmentProcessing header for email messages.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

$BypassRules = @($TransportRule | Where-Object {$_.SetHeaderName -eq "X-MS-Exchange-Organization-SkipSafeAttachmentProcessing"})

If($BypassRules.Count -gt 0) {
    ForEach($Rule in $BypassRules) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Transport Rule'=$Rule.Name
            'Setting'='SafeAttachments is bypassed'
            'Result'='Fail'
        })
    }
} Else {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Transport Rule'='Transport Rules'
        'Setting'='SafeAttachments not bypassed'
        'Result'='Pass'
    })    
}

$TestDefinition.TestResult=$Return