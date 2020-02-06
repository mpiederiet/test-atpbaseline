#InputRequired 'EXO:AtpPolicyForO365'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Safe Links Tracking in Office'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Advanced Threat Protection Policies'
    'PassText'='Safe Links Polices are tracking when user clicks on safe links in Office 365 ProPlus desktop clients and Office Mobile apps.'
    'FailRecommendation'='Enable tracking of user clicks in the O365 ATP Policy'
    'Importance'='When these options are configured, click data for URLs in Word, Excel, PowerPoint and Visio documents is stored by Safe Links. This information can help dealing with phishing, suspicious email messages and URLs.'
    'Links'=@{}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $AtpPolicyForO365) {
    # In ORCA version 1.3.2, this was in check '156', but it makes more sense to add this in a new test so here it is
    If(-not $Policy.TrackClicks -and $($Policy.EnableSafeLinksForClients -or $Policy.EnableSafeLinksForWebAccessCompanion -or $Policy.EnableSafeLinksForO365Clients)) { 		 
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'ATP Policy'=$($Policy.Name)
            'Setting'='TrackClicks'
            'Value'=$Policy.TrackClicks
            'Result'='Fail'
        })
    } ElseIf ($Policy.TrackClicks -eq $True) {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'ATP Policy'=$($Policy.Name)
            'Setting'='TrackClicks'
            'Value'=$Policy.TrackClicks
            'Result'='Pass'
        })
    }
}

$TestDefinition.TestResult=$Return