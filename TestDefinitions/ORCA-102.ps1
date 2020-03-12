#InputRequired 'EXO:HostedContentFilterPolicy'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Advanced Spam Filter (ASF)'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Content Filter Policies'
    'PassText'='Advanced Spam filter options are turned off'
    'FailRecommendation'='Turn off Advanced Spam filter (ASF) options in Content filter policies'
    'Importance'='Settings in the Advanced Spam Filter (ASF) are currently being deprecated. It is recommended to disable ASF settings.'
    'Links'=@{'Recommended settings for EOP and Office 365 ATP security'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop';'Advanced spam filtering options'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/advanced-spam-filtering-asf-options'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

ForEach($Policy in $HostedContentFilterPolicy) {
    # Determine if ASF options are off or not
    If($Policy.IncreaseScoreWithImageLinks -eq 'On' -or $Policy.IncreaseScoreWithNumericIps -eq 'On' -or $Policy.IncreaseScoreWithRedirectToOtherPort -eq 'On' -or $Policy.IncreaseScoreWithBizOrInfoUrls -eq 'On' -or $Policy.MarkAsSpamEmptyMessages -eq 'On' -or $Policy.MarkAsSpamJavaScriptInHtml -eq 'On' -or $Policy.MarkAsSpamFramesInHtml -eq 'On' -or $Policy.MarkAsSpamObjectTagsInHtml -eq 'On' -or $Policy.MarkAsSpamEmbedTagsInHtml -eq 'On' -or $Policy.MarkAsSpamFormTagsInHtml -eq 'On' -or $Policy.MarkAsSpamWebBugsInHtml -eq 'On' -or $Policy.MarkAsSpamSensitiveWordList -eq 'On' -or $Policy.MarkAsSpamFromAddressAuthFail -eq 'On' -or $Policy.MarkAsSpamNdrBackscatter -eq 'On' -or $Policy.MarkAsSpamSpfRecordHardFail -eq 'On') {
        If($Policy.IncreaseScoreWithImageLinks -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='IncreaseScoreWithImageLinks'
                'Value'=$Policy.IncreaseScoreWithImageLinks
                'Result'='Fail'
            })
        }
        If ($Policy.IncreaseScoreWithNumericIps -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='IncreaseScoreWithNumericIps'
                'Value'=$Policy.IncreaseScoreWithNumericIps
                'Result'='Fail'
            })
        }
        If ($Policy.IncreaseScoreWithRedirectToOtherPort -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='IncreaseScoreWithRedirectToOtherPort'
                'Value'=$Policy.IncreaseScoreWithRedirectToOtherPort
                'Result'='Fail'
            })
        }
        If ($Policy.IncreaseScoreWithBizOrInfoUrls -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='IncreaseScoreWithBizOrInfoUrls'
                'Value'=$Policy.IncreaseScoreWithBizOrInfoUrls
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamEmptyMessages -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamEmptyMessages'
                'Value'=$Policy.MarkAsSpamEmptyMessages
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamJavaScriptInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamJavaScriptInHtml'
                'Value'=$Policy.MarkAsSpamJavaScriptInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamFramesInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamFramesInHtml'
                'Value'=$Policy.MarkAsSpamFramesInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamObjectTagsInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamObjectTagsInHtml'
                'Value'=$Policy.MarkAsSpamObjectTagsInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamEmbedTagsInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamEmbedTagsInHtml'
                'Value'=$Policy.MarkAsSpamEmbedTagsInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamFormTagsInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamFormTagsInHtml'
                'Value'=$Policy.MarkAsSpamFormTagsInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamWebBugsInHtml -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamWebBugsInHtml'
                'Value'=$Policy.MarkAsSpamWebBugsInHtml
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamSensitiveWordList -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamSensitiveWordList'
                'Value'=$Policy.MarkAsSpamSensitiveWordList
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamFromAddressAuthFail -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamFromAddressAuthFail'
                'Value'=$Policy.MarkAsSpamFromAddressAuthFail
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamNdrBackscatter -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamNdrBackscatter'
                'Value'=$Policy.MarkAsSpamNdrBackscatter
                'Result'='Fail'
            })
        }
        If ($Policy.MarkAsSpamSpfRecordHardFail -eq 'On') {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Content Filter Policy'=$Policy.Name
                'Setting'='MarkAsSpamSpfRecordHardFail'
                'Value'=$Policy.MarkAsSpamSpfRecordHardFail
                'Result'='Fail'
            })
        }
    } else {
        $Null=$Return.Add([PSCustomObject][Ordered]@{
            'Content Filter Policy'=$Policy.Name
            'Setting'='All ASF Options'
            'Value'='All options disabled'
            'Result'='Pass'
        })
    }
}

$TestDefinition.TestResult=$Return