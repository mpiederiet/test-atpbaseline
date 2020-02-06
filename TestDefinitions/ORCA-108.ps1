#InputRequired 'EXO:AcceptedDomain','EXO:DkimSigningConfig'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Signing Configuration'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='DKIM'
    'PassText'='DKIM signing is set up for all your custom domains'
    'FailRecommendation'='Set up DKIM signing to sign your emails'
    'Importance'='DKIM signing can help protect the authenticity of your messages in transit and can assist with deliverability of your email messages.'
    'Links'=@{'Use DKIM to validate outbound email sent from your custom domain in Office 365'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/use-dkim-to-validate-outbound-email'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

# Check DKIM is enabled
ForEach($Domain in $AcceptedDomain) {
    # Skip onmicrosoft.com domains
    If($Domain.Name -notlike '*.onmicrosoft.com') {
        # Get matching DKIM signing configuration
        $DkimSigning = $DkimSigningConfig | Where-Object {$_.Name -eq $Domain.Name}
        If($null -ne $DkimSigning) {
            if ($DkimSigning.Enabled) {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'Signing Setting'='DKIM Signing Enabled'
                    'Result'='Pass'
                })
            } Else {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'Signing Setting'='DKIM Signing Disabled'
                    'Result'='Fail'
                })
            }
        } Else {
            $Null=$Return.Add([PSCustomObject][Ordered]@{
                'Domain'=$Domain.Name
                'Signing Setting'='No DKIM Signing Config'
                'Result'='Fail'
            })
        }
    }
}

$TestDefinition.TestResult=$Return