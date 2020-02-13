#InputRequired 'EXO:AcceptedDomain','EXO:DkimSigningConfig'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='DNS Records'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='DKIM'
    'PassText'='DNS Records have been set up to support DKIM'
    'FailRecommendation'='Set up the required selector DNS records in order to support DKIM'
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
            # Check DKIM Selector1 Records
            $Selector1=$Null
            Try { $Selector1 = Resolve-DnsName -Type ANY -Name "selector1._domainkey.$($DkimSigning.Domain)" -ErrorAction:stop } Catch {}
            $Selector1=$Selector1|Where-Object{$_.Section -eq 'Answer' -and $_.Type -eq 'CNAME'}
            if($Selector1.NameHost -eq $DkimSigning.Selector1CNAME) {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'DNS Record'="Selector1 CNAME ($($DkimSigning.Selector1CNAME))"
                    'Result'='Pass'
                })    
            } Else {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'DNS Record'="Selector1 CNAME ($($DkimSigning.Selector1CNAME))"
                    'Result'='Fail'
                })    
            }

            # Check DKIM Selector2 Records
            $Selector2=$Null
            Try { $Selector2 = Resolve-DnsName -Type ANY -Name "selector2._domainkey.$($DkimSigning.Domain)" -ErrorAction:stop } Catch {}
            $Selector2=$Selector2|Where-Object{$_.Section -eq 'Answer' -and $_.Type -eq 'CNAME'}
            if($Selector2.NameHost -eq $DkimSigning.Selector2CNAME) {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'DNS Record'="Selector2 CNAME ($($DkimSigning.Selector2CNAME))"
                    'Result'='Pass'
                })
            } Else {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Domain'=$Domain.Name
                    'DNS Record'="Selector2 CNAME ($($DkimSigning.Selector2CNAME))"
                    'Result'='Fail'
                })
            }
        }
    }
}

$TestDefinition.TestResult=$Return