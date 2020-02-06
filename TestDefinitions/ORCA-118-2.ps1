#InputRequired 'EXO:TransportRule'
$MyFileName=[System.IO.FileInfo]($MyInvocation.MyCommand.Path)

# Casting a hashtable to a class: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables?view=powershell-7#creating-objects-from-hash-tables
$TestDefinition=[ATPBaselineCheck]@{
    'Name'='Domain Whitelisting'
    'Control'=$MyFileName.BaseName
    'TestDefinitionFile'=$MyFileName.FullName
    'Area'='Transport Rules'
    'PassText'='Domains are not being whitelisted in an unsafe manner'
    'FailRecommendation'='Remove whitelisting on domains'
    'Importance'='Emails coming from whitelisted domains bypass several layers of protection within Exchange Online Protection. If domains are whitelisted, they are open to being spoofed from malicious actors.'
    'Links'=@{'Using Exchange Transport Rules (ETRs) to allow specific senders'='https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/create-safe-sender-lists-in-office-365#using-exchange-transport-rules-etrs-to-allow-specific-senders-recommended'}
}

Add-TestDefinition -TestDefinition $TestDefinition

$Return = New-Object System.Collections.ArrayList

# Look through Transport Rule for an action SetSCL -1
ForEach($Rule in $TransportRule) {
    If($Rule.SetSCL -eq "-1") {
        #Rules that apply to the sender domain
        #From Address notmatch is to include if just domain name is value
        If($null -ne $Rule.SenderDomainIs -or ($null -ne $Rule.FromAddressContainsWords -and $Rule.FromAddressContainsWords -notmatch ".+@") -or ($null -ne $Rule.FromAddressMatchesPatterns -and $Rule.FromAddressMatchesPatterns -notmatch ".+@")){
            #Look for condition that checks auth results header and its value
            If(($Rule.HeaderContainsMessageHeader -eq 'Authentication-Results' -and $null -ne $Rule.HeaderContainsWords) -or ($Rule.HeaderMatchesMessageHeader -like '*Authentication-Results*' -and $null -ne $Rule.HeaderMatchesPatterns)) {
                # OK
            }
            #Look for exception that checks auth results header and its value 
            elseif(($Rule.ExceptIfHeaderContainsMessageHeader -eq 'Authentication-Results' -and $null -ne $Rule.ExceptIfHeaderContainsWords) -or ($Rule.ExceptIfHeaderMatchesMessageHeader -like '*Authentication-Results*' -and $null -ne $Rule.ExceptIfHeaderMatchesPatterns)) {
                # OK
            }
            elseif($null -ne $Rule.SenderIpRanges) {
                # OK
            }
            #Look for condition that checks for any other header and its value
            else {
                ForEach($RuleDomain in $($Rule.SenderDomainIs)) {
                    $Null=$Return.Add([PSCustomObject][Ordered]@{
                        'Transport Rule'=$($Rule.Name)
                        'Whitelisted Domain'=$($RuleDomain)
                        'Result'='Fail'
                    })  
                }
                ForEach($FromAddressContains in $($Rule.FromAddressContainsWords)) {
                    $Null=$Return.Add([PSCustomObject][Ordered]@{
                        'Transport Rule'=$($Rule.Name)
                        'Whitelisted Domain'="Contains $($FromAddressContains)"
                        'Result'='Fail'
                    })  
                }
                ForEach($FromAddressMatch in $($Rule.FromAddressMatchesPatterns)) {
                    $Null=$Return.Add([PSCustomObject][Ordered]@{
                        'Transport Rule'=$($Rule.Name)
                        'Whitelisted Domain'="Matches $($FromAddressMatch)"
                        'Result'='Fail'
                    })                
                }

            }
        }
        #No sender domain restriction, so check for IP restriction
        elseif($null -ne $Rule.SenderIpRanges) {
            ForEach($SenderIpRange in $Rule.SenderIpRanges) {
                $Null=$Return.Add([PSCustomObject][Ordered]@{
                    'Transport Rule'=$($Rule.Name)
                    'Whitelisted Domain'=$SenderIpRange
                    'Result'='Fail'
                })                
            }
        }
        #No sender restriction, so check for condition that checks auth results header and its value
        elseif(($Rule.HeaderContainsMessageHeader -eq 'Authentication-Results' -and $null -ne $Rule.HeaderContainsWords) -or ($Rule.HeaderMatchesMessageHeader -like '*Authentication-Results*' -and $null -ne $Rule.HeaderMatchesPatterns)) {
            # OK
        }
        #No sender restriction, so check for exception that checks auth results header and its value 
        elseif(($Rule.ExceptIfHeaderContainsMessageHeader -eq 'Authentication-Results' -and $null -ne $Rule.ExceptIfHeaderContainsWords) -or ($Rule.ExceptIfHeaderMatchesMessageHeader -like '*Authentication-Results*' -and $null -ne $Rule.ExceptIfHeaderMatchesPatterns)) {
            # OK
        }
    }
}
# If no rules found with SetSCL -1, then pass.

if($Return.Count -eq 0) {
    $Null=$Return.Add([PSCustomObject][Ordered]@{
        'Transport Rule'='Transport Rules'
        'Whitelisted Domain'='No SetSCL -1 actions found'
        'Result'='Pass'
    })
}

$TestDefinition.TestResult=$Return