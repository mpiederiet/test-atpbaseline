#InputRequired 'IntuneGraph:/deviceManagement/templates','IntuneGraph:/deviceManagement/intents'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Assign Microsoft Defender Advanced Threat Protection Baseline'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Services'=[BaseLineCheckService]::DefenderATP
    'Area'='Microsoft Defender ATP Baseline'
    'PassText'='You have assigned at least one Microsoft Defender ATP Baseline policy to at least one device.'
    'FailRecommendation'='Assign Intune Microsoft Defender ATP security baselines to your devices.'
    'Importance'='Assign the Intune security baselines to help you secure and protect your users and devices. A policy that is not assigned is not effective.'
    'Links'=@{'Use security baselines to configure Windows 10 devices in Intune'='https://docs.microsoft.com/en-us/intune/protect/security-baselines'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

Function Get-DefenderATPTemplates {
    Return ($deviceManagement_templates | Where-Object {$_.templateType -eq 'advancedThreatProtectionSecurityBaseline'})
}

Function Get-DefenderATPPolicies {
    $Result=New-Object System.Collections.ArrayList

    $Templates=Get-DefenderATPTemplates
    if ($null -ne $Templates) {
        ForEach ($Template in $Templates) {
            $ATPTemplateID=$Template.id
            $ATPPolicies=($deviceManagement_intents | Where-Object {$_.templateId -eq $ATPTemplateID})
            ForEach ($ATPPolicy in $ATPPolicies) {
                $Null=$Result.Add([PSCustomObject][Ordered]@{
                    'Name'=$ATPPolicy.displayName
                    'Assignments'=(Invoke-GraphRequest "/deviceManagement/intents/$($ATPPolicy.ID)/assignments").Value
                })
            }
        }
    }
    Return $Result
}

$DefenderATPPolicies=Get-DefenderATPPolicies

ForEach($Policy in $DefenderATPPolicies) {
    # Check whether the found policies are assigned
    if ($Policy.Assignments.Count -gt 0) {
        if ($Policy.Assignments.Count -eq 1) {
            $AssignmentsWord='assignment'
        } Else {
            $AssignmentsWord='assignments'
        }
        $Null=$Return.Add([Ordered]@{
            'Defender ATP Policy'=$Policy.Name
            'Assignments'="Policy has $($Policy.Assignments.Count) $AssignmentsWord"
            '__Level'=[BaseLineCheckLevel]::Standard
        })
    } Else {
        $Null=$Return.Add([Ordered]@{
            'Defender ATP Policy'=$Policy.Name
            'Assignments'='Policy has no assignments'
            '__Level'=[BaseLineCheckLevel]::None
        })
    }
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([Ordered]@{
        'Defender ATP Policy'='No Baseline policies defined'
        'Finding'='No Baseline policies defined'
        '__Level'=[BaseLineCheckLevel]::None
    })
}

$TestDefinition.TestResult=$Return