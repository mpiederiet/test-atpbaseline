#InputRequired 'IntuneGraph:/deviceManagement/templates','IntuneGraph:/deviceManagement/intents'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Use Microsoft Defender Advanced Threat Protection Baseline defaults'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Microsoft Defender ATP Baseline'
    'PassText'='All settings are configured as by the recommended defaults.'
    'FailRecommendation'='Please ensure you are using the recommended default settings. Check the changed settings and correct them where necessary.'
    'Importance'='Changing the settings from the recommended defaults might pose a security risk for your users and devices.'
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
                    'Settings'=(Invoke-GraphRequest "/deviceManagement/intents/$($ATPPolicy.ID)/settings").Value
                })
            }
        }
    }
    Return $Result
}

$DefenderATPPolicies=Get-DefenderATPPolicies
$DefaultBaselineSettings=Get-Content '.\Microsoft Defender ATP Baseline Defaults.json' | ConvertFrom-Json
# Make a hashtable for easy lookup of default values
$DefaultBaselineLookup=@{}
$DefaultBaselineSettings|ForEach-Object {$DefaultBaselineLookup[$_.definitionId]=$_.valueJson}

ForEach($Policy in $DefenderATPPolicies) {
    # Compare the baseline settings with the defaults. Report any deviations
    $ThisPolicyOK=$True
    $SettingsDiff=Compare-Object -ReferenceObject $DefaultBaselineSettings -DifferenceObject $Policy.Settings -Property 'definitionId','valueJson'
    if ($SettingsDiff.Count -gt 0) {
        ForEach ($SettingDiff in ($SettingsDiff | Where-Object {$_.SideIndicator -eq '=>'})) {
            $ThisPolicyOK=$False
            $ReadableDefinitionId=$SettingDiff.definitionId -replace 'deviceConfiguration--','' -replace '_','/'
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Defender ATP Policy'=$Policy.Name
                'Setting'="$($ReadabledefinitionId)"
                'Default value'=$DefaultBaselineLookup[$SettingDiff.definitionId]
                'Set Value'=$SettingDiff.valueJson
                'Result'='Fail'
            })
        }
    }
    if ($ThisPolicyOK) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Defender ATP Policy'=$Policy.Name
            'Finding'='No settings have been changed from the recommended baseline'
            'Result'='Pass'
        })    
    }
}

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Defender ATP Policy'='No Baseline policies defined'
        'Finding'='No Baseline policies defined'
        'Result'='Fail'
    })
}

$TestDefinition.TestResult=$Return