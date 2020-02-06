#InputRequired 'IntuneGraph:/deviceManagement/templates','IntuneGraph:/deviceManagement/intents'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Microsoft Defender Advanced Threat Protection Baseline'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Microsoft Defender ATP Baseline'
    'PassText'='You have created at least one Microsoft Defender ATP Baseline policy.'
    'FailRecommendation'='Create an Intune security baseline based on the Microsoft Defender ATP Baseline template.'
    'Importance'='Use Intune''s security baselines to help you secure and protect your users and devices. Security baselines are pre-configured groups of Windows settings that help you apply a known group of settings and default values that are recommended by the relevant security teams.'
    'Links'=@{'Use security baselines to configure Windows 10 devices in Intune'='https://docs.microsoft.com/en-us/intune/protect/security-baselines'}
}
Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

Function Get-DefenderATPTemplates {
    Return ($deviceManagement_templates.value | Where-Object {$_.templateType -eq 'advancedThreatProtectionSecurityBaseline'})
}

Function Get-DefenderATPPolicies {
    $Result=New-Object System.Collections.ArrayList

    $Templates=Get-DefenderATPTemplates
    if ($null -ne $Templates) {
        ForEach ($Template in $Templates) {
            $ATPTemplateID=$Template.id
            $ATPPolicies=($deviceManagement_intents.Value | Where-Object {$_.templateId -eq $ATPTemplateID})
            ForEach ($ATPPolicy in $ATPPolicies) {
                $Null=$Result.Add([PSCustomObject][Ordered]@{
                    'Name'=$ATPPolicy.displayName
                })
            }
        }
    }
    Return $Result
}

$DefenderATPPolicies=Get-DefenderATPPolicies

ForEach($Policy in $DefenderATPPolicies) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Defender ATP Policy'=$Policy.Name
        'Finding'="Policy is based on the Microsoft Defender ATP Baseline"
        'Result'='Pass'
    })
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Defender ATP Policy'='No Baseline policies defined'
        'Finding'='No Baseline policies defined'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return