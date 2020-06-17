#Requires -Module 'PackageManagement','DnsClient','PowerShellGet'
Set-StrictMode -version latest
Set-PSdebug -Strict
[Version]$Script:TestATPBaselineVersion='1.2'
$Script:PreloadedCommands=New-Object System.Collections.ArrayList

# BaseLineCheckService
# Indicates the service(s) the check was applied to
[Flags()]
enum BaseLineCheckService
{
    EOP = 1
    OfficeATP = 2
    AzureATP = 4
    DefenderATP = 8
}

# BaseLineCheckLevel
# Indicates the level of "Pass" items (Informational, Standard, Strict). Failed items have level "None"
enum BaseLineCheckLevel {
    None = 0
    Informational = 4
    Standard = 5
    Strict = 10
    TooStrict = 15
}

# BaseLineCheckResult
# Indicates the result of the check
enum BaseLineCheckResult {
    Fail = 0
    Informational = 1
    Pass = 2
}

<#
    ATPBaseLineCheck definition

    The checks defined below allow contextual information to be added in to the report HTML document.
    - Name                  : A unique name for the test
    - Control               : A unique identifier that can be used to index the results back to the check
    - TestDefinitionFile    : The full path to the .ps1 file containing this test. Value is populated by the test scripts when loaded.
    - Area                  : The area that this check should appear within the report
    - PassText              : The text that should appear in the report when this 'control' passes
    - FailRecommendation    : The text that appears as a title when the 'control' fails. Short, descriptive. E.g "Do this"
    - Importance            : Why this is important
    - TestResult            : A collection of objects as a result of the performed test (Result='Pass' or Result='Fail' for each object)
    - Links                 : Hashtable of links containing more information regarding the setting
    - CheckResult           : 'Pass' when no objects in TestResult are found that have 'Fail' as result. Otherwise 'Fail'
#>
Class ATPBaselineCheck {
    [String]$Name
    [String]$Control
    [String]$TestDefinitionFile
    [BaseLineCheckService]$Services
    [String]$Area
    [String]$PassText
    [String]$FailRecommendation
    [String]$Importance
    [System.Collections.Specialized.OrderedDictionary[]]$TestResult
    [HashTable]$Links
    ATPBaselineCheck () {
        # Add a Dynamically generated property to the class
        Add-Member -InputObject $This -MemberType 'ScriptProperty' -Name 'CheckResult' -Value {
            # If there are no testresults, or it is a single boolean '$False', or when at least one 'Fail' entry is present, mark the test as failed
            $FailCount=0
            $PassCount=0
            $InfoCount=0
            if ($this.TestResult.Count -eq 0) {
                # No test results, mark as failed
                $FailCount=1
            } Elseif ($this.TestResult[0]['__TestResult'] -is [bool]) {
                # Test result is a single bool value, check it whether it was a pass or fail
                if (-not $This.TestResult[0]['__TestResult']) {
                    $FailCount=1
                } Else {
                    $PassCount=1
                }
            } Else {
                # Check the test results for Pass/Fail/Informational items
                $FailCount = @($this.TestResult | Where-Object {$_['__Level'] -eq [BaseLineCheckLevel]::None}).Count
                $PassCount = @($this.TestResult | Where-Object {$_['__Level'] -eq [BaseLineCheckLevel]::Standard -or $_['__Level'] -eq [BaseLineCheckLevel]::Strict}).Count
                $InfoCount = @($this.TestResult | Where-Object {$_['__Level'] -eq [BaseLineCheckLevel]::Informational}).Count
            }
    
            If ($FailCount -eq 0) {
                if ($InfoCount -eq 0) {
                    return [BaseLineCheckResult]::Pass
                } Else {
                    return [BaseLineCheckResult]::Informational
                }
            } Else {
                return [BaseLineCheckResult]::Fail
            }
        }
    }
}

function Add-TestDefinition ($TestDefinition) {
    $Null=$Script:TestDefinitions.Add($TestDefinition)
}

# Helper function used in TestDefinition files
Function New-ReturnObject ([object]$InputObject,[string]$ObjectName,[string]$NameProperty,[string]$Property,[ScriptBlock]$TestScript) {
    Write-debug "$($MyInvocation.MyCommand): Entered function"
    Write-debug "Bound parameters:`n$($PSBoundParameters | out-string)"
    if (Invoke-Expression ([string]$TestScript)) {
        $Result='Pass'
    } Else {
        $Result='Fail'
    }
    Return ([PSCustomObject][Ordered]@{
        $ObjectName=$InputObject.$NameProperty
        'Setting'=$Property
        'Value'=$InputObject.$Property
        'Result'=$Result
    })
}

# Display a dialog box containing a checkbox item list 
Function New-ListBoxDialog ([string]$FormTitle,[string]$Explanation,[string[]]$ListItems,[string]$DefaultItem) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = $FormTitle
    $FormSize=New-Object System.Drawing.Size(320,220)
    $Form.Size = $FormSize
    $Form.MinimumSize = $FormSize
    $Form.StartPosition = 'CenterScreen'
    $Form.AutoSize=$False
    $Form.ShowIcon=$false
    $Form.FormBorderStyle='Sizable'

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,5)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $Explanation
    $Form.Controls.Add($label)

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(70,150)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.Anchor='Left, Bottom'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $Form.AcceptButton = $OKButton
    $Form.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(160,150)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.Anchor='Left, Bottom'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $Form.CancelButton = $CancelButton
    $Form.Controls.Add($CancelButton)

    $listBox = New-Object System.Windows.Forms.CheckedListBox
    $listBox.Location = New-Object System.Drawing.Point(10,45)
    $listBox.Size = New-Object System.Drawing.Size(280,100)
    $listbox.CheckOnClick = $True
    $listbox.AutoSize=$true
    $ListBox.Anchor='Top, Bottom, Left, Right'

    [void] $listBox.Items.AddRange($ListItems)

    # look for the default item and check it by default
    $ItemIndex=$ListBox.FindString($DefaultItem)
    if ($ItemIndex -ne -1) {
        $ListBox.SetItemChecked($ItemIndex,$true)
    }

    $Form.Controls.Add($listBox)

    $label = New-Object System.Windows.Forms.LinkLabel
    $label.Location = New-Object System.Drawing.Point(10,25)
    $label.Size = New-Object System.Drawing.Size(70,20)
    $label.LinkColor = 'green'
    $label.ActiveLinkColor = 'blue'
    $label.Text = 'Select all'
    $label.Add_Click({
        0..($listBox.Items.Count-1)|ForEach-Object{$ListBox.SetItemChecked($_,$true)}
      })
    $Form.Controls.Add($label)

    $label = New-Object System.Windows.Forms.LinkLabel
    $label.Location = New-Object System.Drawing.Point(100,25)
    $label.Size = New-Object System.Drawing.Size(70,20)
    $label.LinkColor = 'red'
    $label.ActiveLinkColor = 'blue'
    $label.Text = 'Select none'
    $label.Add_Click({
        0..($listBox.Items.Count-1)|ForEach-Object{$ListBox.SetItemChecked($_,$false)}
      })    
    $Form.Controls.Add($label)

    $Form.Topmost = $true

    $Result = $Form.ShowDialog()

    if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $listBox.CheckedItems
    } Else {
        Return $null
    }
}

# https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/    
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}
Function New-HtmlOutput {
    Param(
        [System.Array]$InputObject,
        [string]$TenantDomain
    )
    <#
        OUTPUT GENERATION / Header
    #>

    Write-Debug "Generating HTML Output"

    # Obtain the tenant domain and date for the report
    $ReportDate=$(Get-Date -format 'dd-MMM-yyyy HH:mm')

    # Summary
    $RecommendationCount=($InputObject | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Fail}|Measure-Object).Count
    $OKCount=($InputObject | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Pass}|Measure-Object).Count
    $InfoCount=($InputObject | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Informational}|Measure-Object).Count

    # Misc
    $ReportTitle='Office 365 ATP Recommended Configuration Analyzer Report'

    # Area icons
    $AreaIcon=@{}
    $AreaIcon['Default']='fas fa-user-cog'

    if (Test-Path '.\AreaIcons.json') {
        try {
            $AreaIcon=Get-Content .\AreaIcons.json|ConvertFrom-Json|ConvertTo-Hashtable
        }
        catch {
            # An error occured while loading the AreaIcons JSON mapping file
            Write-Warning "An error occured while attempting to load AreaIcons.json: $_"
        }
    }

    # Output start
    $output=@"
<!doctype html>
<html lang='en'>
    <head>
        <!-- Required meta tags -->
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>
        <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/css/all.min.css' integrity='sha384-KA6wR/X5RY4zFAHpv/CnoG2UW1uogYfdnP67Uv7eULvTveboZJg0qUpmJZb5VqzN' crossorigin='anonymous'>
        <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css' integrity='sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T' crossorigin='anonymous'>
        <script src='https://code.jquery.com/jquery-3.3.1.slim.min.js' integrity='sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo' crossorigin='anonymous'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js' integrity='sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1' crossorigin='anonymous'></script>
        <script src='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js' integrity='sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM' crossorigin='anonymous'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/js/all.js' integrity=integrity='sha384-HLQE0seKUbwMhISlWaz8332Qg5JRRxy6HkzymHFYT4d3SCEU4+sV9ec+uhEQKPCS' crossorigin='anonymous'></script>
        <style>
        .table-borderless td,
        .table-borderless th {
            border: 0;
        }
        .bd-callout {
            padding: 1.25rem;
            margin-top: 1.25rem;
            margin-bottom: 1.25rem;
            border: 1px solid #eee;
            border-left-width: .25rem;
            border-radius: .25rem
        }        
        .bd-callout h4 {
            margin-top: 0;
            margin-bottom: .25rem
        }        
        .bd-callout p:last-child {
            margin-bottom: 0
        }        
        .bd-callout code {
            border-radius: .25rem
        }
        .bd-callout+.bd-callout {
            margin-top: -.25rem
        }        
        .bd-callout-info {
            border-left-color: #5bc0de
        }        
        .bd-callout-info h4 {
            color: #5bc0de
        }        
        .bd-callout-warning {
            border-left-color: #f0ad4e
        }        
        .bd-callout-warning h4 {
            color: #f0ad4e
        }        
        .bd-callout-danger {
            border-left-color: #d9534f
        }        
        .bd-callout-danger h4 {
            color: #d9534f
        }
        .bd-callout-success {
            border-left-color: #00bd19
        }
        </style>
        <title>$($ReportTitle)</title>
    </head>
    <body class='app header-fixed bg-light'>
        <nav class='navbar fixed-top navbar-light bg-white p-3 border-bottom'>
            <div class='container-fluid'>
                <div class='col-sm' style='text-align:left'>
                    <div class='row'><div><i class='fas fa-edit'></i></div><div class='ml-3'><strong>ATP Baseline Report</strong></div></div>
                </div>
                <div class='col-sm' style='text-align:center'>
                    <strong>$($TenantDomain)</strong>
                </div>
                <div class='col-sm' style='text-align:right'>
                    $($ReportDate)
                </div>
            </div>
        </nav>  
        <div class='app-body p-3'>
            <main class='main'>
                <!-- Main content here -->
                <div class='container' style='padding-top:50px;'></div>
                <div class='card'>                        
                    <div class='card-body'>
                        <h2 class='card-title'>$($ReportTitle)</h5>
                        <strong>Version $($TestATPBaselineVersion.ToString())</strong>
                        <p>This report details any tenant configuration changes recommended within your tenant.</p>`r`n
"@

    # If EOP services are tested, check whether OfficeATP was also found
    If((([BaseLineCheckService]$InputObject.Services) -band [BaseLineCheckService]::EOP) -and -not (([BaseLineCheckService]$InputObject.Services) -band [BaseLineCheckService]::OfficeATP)) {
        $Output+=@"
                        <div class='alert alert-danger pt-2' role='alert'>
                            <p>Office Advanced Threat Protection (ATP) was <strong>NOT</strong> detected on this tenant. <strong>The purpose of Test-ATPBaseLine/ORCA is to check for Office ATP recommended configuration</strong> - <i>however, these checks will be skipped. Other results should be relevant to base EOP configuration.</i></p>
                            <p>Consider Office Advanced Threat Protection for:<ul><li>Automatic incident response capabilities</li><li>Attack simulation capabilities</li><li>Behavioural analysis (sandboxing) of malware</li><li>Time of click protection against URLs</li><li>Advanced anti-phishing controls</li></ul></p>
                        </div>`r`n
"@
    }

    $Output+=@"
                    </div>
                </div>`r`n
"@



    <#
        OUTPUT GENERATION / Summary cards
    #>
    $Output+=@"
                <div class='row p-3'>`r`n
"@

    if($InfoCount -gt 0) {
        $Output+=@"
                    <div class='col d-flex justify-content-center text-center'>
                        <div class='card text-white bg-secondary mb-3' style='width: 18rem;'>
                            <div class='card-header'><h5>Informational</h5></div>
                            <div class='card-body'>
                                <h2>$($InfoCount)</h2>
                            </div>
                        </div>
                    </div>`r`n
"@
    }

$Output+=@"
                    <div class='col d-flex justify-content-center text-center'>
                        <div class='card text-white bg-warning mb-3' style='width: 18rem;'>
                            <div class='card-header'><h5>Recommendations</h5></div>
                            <div class='card-body'>
                                <h2>$($RecommendationCount)</h2>
                            </div>
                        </div>
                    </div>
                    <div class='col d-flex justify-content-center text-center'>
                        <div class='card text-white bg-success mb-3' style='width: 18rem;'>
                            <div class='card-header'><h5>OK</h5></div>
                            <div class='card-body'>
                                <h2>$($OKCount)</h2>
                            </div>
                        </div>
                    </div>
                </div>`r`n
"@
    <#
        OUTPUT GENERATION / Summary
    #>
    $Output+=@"
                <div class='card m-3'>
                    <div class='card-header'><h3>Summary</h3></div>
                    <div class='card-body'>
                        <h4>Areas</h4>
                        <table class='table table-borderless'>`r`n
"@

    ForEach($Area in ($InputObject | Group-Object Area)) {
        $Pass=@($Area.Group | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Pass}).Count
        $Fail=@($Area.Group | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Fail}).Count
        $Info=@($Area.Group | Where-Object {$_.CheckResult -eq [BaseLineCheckResult]::Informational}).Count
        $Icon=$AreaIcon[$Area.Name]
        If($Null -eq $Icon) { $Icon=$AreaIcon["Default"]}

        $Output+=@"
                            <tr>
                                <td width='20'><i class='$Icon'></i>
                                <td><a href='`#$($Area.Name)'>$($Area.Name)</a></td>
                                <td align='right'>
                                    <span class='badge badge-secondary' style='padding:15px;text-align:center;width:40px;$(if($Info -eq 0) { "opacity: 0.1;" })'>$($Info)</span>
                                    <span class='badge badge-warning' style='padding:15px;text-align:center;width:40px;$(if($Fail -eq 0) { "opacity: 0.1;" })'>$($Fail)</span>
                                    <span class='badge badge-success' style='padding:15px;text-align:center;width:40px;$(if($Pass -eq 0) { "opacity: 0.1;" })'>$($Pass)</span>
                                </td>
                            </tr>`r`n
"@
    }

    $Output+=@"
                        </table>
                    </div>
                </div>`r`n
"@
    <#
        OUTPUT GENERATION / Zones
    #>
    ForEach ($Area in ($InputObject | Group-Object Area)) {
        # Write the top of the card
        $Output+=@"
                <div class='card m-3'>
                    <div class='card-header'>
                        <a name='$($Area.Name)'><h3>$($Area.Name)</h3></a>
                    </div>
                    <div class='card-body'>`r`n
"@

        # Each check
        ForEach ($Check in $Area.Group) {
            $Output+=@"
                        <h4>$($Check.Name)</h4>`r`n
"@

            If($Check.CheckResult -eq [BaseLineCheckResult]::Pass) {
                $CalloutType='bd-callout-success'
                $BadgeType='badge-success'
                $BadgeName='OK'
                $Icon='fas fa-thumbs-up'
                $Title=$Check.PassText
            } ElseIf ($Check.CheckResult -eq [BaseLineCheckResult]::Informational) {
                $CalloutType='bd-callout-secondary'
                $BadgeType='badge-secondary'
                $BadgeName='Informational'
                $Icon='fas fa-thumbs-up'
                $Title=$Check.FailRecommendation
            } Else {
                $CalloutType='bd-callout-warning'
                $BadgeType='badge-warning'
                $BadgeName='Improvement'
                $Icon='fas fa-thumbs-down'
                $Title=$Check.FailRecommendation
            }

            $Output+=@"
                        <div class='bd-callout $($CalloutType) b-t-1 b-r-1 b-b-1 p-3'>
                            <div class='container-fluid'>
                                <div class='row'>
                                    <div class='col-1'><i class='$($Icon)'></i></div>
                                    <div class='col-8'><h5>$($Title)</h5></div>
                                    <div class='col' style='text-align:right'><h5><span class='badge $($BadgeType)'>$($BadgeName)</span></h5></div>
                                </div>`r`n
"@
            if($Check.Importance) {
                    $Output+=@"
                                <div class='row p-3'>
                                    <div><p>$($Check.Importance)</p></div>
                                </div>`r`n
"@

            }
            $TestBool=$False
            If([bool]::TryParse($Check.TestResult[0]['__TestResult'],[ref]$TestBool) -ne $True) {
                # make a new table for each object type in the test result set
                $GroupedByColumnHeader=$Check.TestResult | Group-Object {([string[]]$_.Keys)[0]},{([string[]]$_.Keys)[1]}
                $Output+=@"
                                <h6>Effected objects</h6>
                                <div class='row pl-2 pt-3'>`r`n
"@
                ForEach ($ColumnGroup in $GroupedByColumnHeader) {
                    # We should expand the results by showing a table of Config Data and Items
                    # First, determine the number of properties. 'Result' is assumed to always be present and is the last column of the table
                    $ColumnHeaders=[string[]]($ColumnGroup.group[0].keys|Where-Object{$_ -notmatch '^__.*$'})
                    $ColumnCount=$ColumnHeaders.count
                    $Output+=@"
                                    <table class='table'>
                                        <thead class='border-bottom'>
                                            <tr>`r`n
"@
                    0..($ColumnCount-1)|ForEach-Object{
                        $Output+=@"
                                                <th>$($ColumnHeaders[$_])</th>`r`n
"@
                    }
                    $Output+=@"
                                                <th style='width:50px'></th>
                                            </tr>
                                        </thead>
                                        <tbody>`r`n
"@
                    ForEach($o in $ColumnGroup.Group) {
                        switch ($o['__Level']) {
                            {$_ -notin ([BaseLineCheckLevel]::None,[BaseLineCheckLevel]::Informational)} {
                                $oicon="fas fa-check-circle text-success"
                                $levelText=$_.ToString()
                                break;
                            }
                            {$_ -eq [BaseLineCheckLevel]::Informational} {
                                $oicon="fas fa-info-circle text-muted"
                                $levelText=$_.ToString()
                                break;                                
                            }
                            default {
                                $oicon="fas fa-times-circle text-danger"
                                $levelText='Not recommended'
                                break;
                            }
                        }
                        $Output+=@"
                                            <tr>`r`n
"@
                        $ColumnValues=$ColumnHeaders.ForEach({[string]$o[$_]})
                        0..($ColumnCount-1)|ForEach-Object{
                            $Output+=@"
                                                <td>$($ColumnValues[$_])</td>`r`n
"@
                        }
                        $Output+=@"
                                                <td style='text-align:right'>
                                                    <div class='row badge badge-pill badge-light'>
                                                        <span style='vertical-align: middle;'>$($LevelText)</span>
                                                        <span class='$($oicon)' style='vertical-align: middle;'></span>
                                                    </div>
                                                </td>                                                
                                            </tr>`r`n
"@

                        # Informational segment
                        if($o['__Level'] -eq [BaseLineCheckLevel]::Informational) {
                            $Output+=@"
                                            <tr>
                                                <td colspan='$($ColumnCount+1)' style='border: 0;'>
                                                    <div class='alert alert-light' role='alert' style='text-align: right;'>
                                                        <span class='fas fa-info-circle text-muted' style='vertical-align: middle; padding-right:5px'></span>
                                                        <span style='vertical-align: middle;'>$($o['__InfoText'])</span>
                                                    </div>
                                                </td>
                                            </tr>`r`n
"@
                        }
                    }
                    $Output+=@"
                                        </tbody>
                                    </table>`r`n
"@
                }

                # If any links exist
                If($Check.Links.Count -gt 0) {
                    $Output+=@"
                                    <table>`r`n
"@
                    ForEach($Link in $Check.Links.GetEnumerator()) {
                        $Output+=@"
                                        <tr>
                                            <td style='width:40px'><i class='fas fa-external-link-alt'></i></td>
                                            <td><a href='$($Link.Value)' target='_blank'>$($Link.Name)</a></td>
                                        <tr>`r`n
"@
                    }
                    $Output+=@"
                                    </table>`r`n
"@
                }
                $Output+=@"
                                </div>`r`n
"@
            }
            $Output+=@"
                            </div>
                        </div>`r`n
"@
        }            

        # End the card
        $Output+=@"
                    </div>
                </div>`r`n
"@
    }
    <#
        OUTPUT GENERATION / Footer
    #>
    $Output+=@"
            </main>
        </div>
        <footer class='app-footer'>
            <!-- Footer content here -->
        </footer>
    </body>
</html>`r`n
"@

    Return $Output
}

Function Test-ATPBaseline (
    [string]$OutputPath=$null,
    [switch]$OutputRawResultsFile,
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "File or folder does not exist" 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The InputPath argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [System.IO.FileInfo]$InputPath) {
    $MainTitle='ATP Baseline Test'
    $Script:TenantDomain=''

    $Script:TestDefinitions=New-Object System.Collections.ArrayList

    if (-not [string]::IsNullOrEmpty($InputPath) -and (Test-Path $InputPath)) {
        Write-Progress -Activity $MainTitle -Status "Loading inputfile $InputPath"
        # Load JSON file and perform some trickery to force the "Links" collection back to a hashtable
        $Script:TestDefinitions=(Get-Content $InputPath|ConvertFrom-Json)|Select-Object *,@{Name='Links';Expression={$_.Links|ConvertTo-Hashtable}} -ExcludeProperty Links
        Write-Verbose "$(Get-Date) Loaded JSON file has $($BaselineChecks.Count) tests and $(($BaselineChecks|Where-Object {$_.TestResult}|Measure-Object).Count) corresponding results"

        # Check for 'globals' inputfile
        $GlobalsInput=$InputPath -replace '\.json$','.global.xml'
        if (Test-Path ($GlobalsInput)) {
            Write-Progress -Activity $MainTitle -Status "Loading global variables"
            [hashtable]$Globals=Import-CliXML $GlobalsInput
            $Globals.GetEnumerator()|ForEach-Object {
                Set-Variable -Scope 'Script' -Name $_.Name -Value $_.Value
            }
        }
    } Else {
        Write-Progress -Activity $MainTitle -Status "Checking for test definitions in TestDefitinions folder"
        $FilesInTestDefinitionFolder=@(Get-ChildItem '.\TestDefinitions\*.ps1'|Select-Object -Expand FullName)
        Write-Verbose "$(Get-Date) TestDefinitions folder has $($FilesInTestDefinitionFolder.Count) test definition files"

        Write-Progress -Activity $MainTitle -Status "Looking for commands to preload"
        # Parse the headers of the .ps1 files, look for #InputRequired and a comma-delimited list of Module:Command to be preloaded
        $CommandsToPreload=@{}
        if ($FilesInTestDefinitionFolder.Count -gt 0) {
            $RegExCmdletMatches=(Select-String -Pattern '^#InputRequired ([''"]?(?<module>[a-zA-Z0-9]+):(?<command>[a-zA-Z0-9/]+)[''"]?(?:,[''"]?(?<module>[a-zA-Z0-9]+):(?<command>[a-zA-Z0-9/]+)[''"]?)*)' $FilesInTestDefinitionFolder|Select-Object -Expand matches)
            $CommandsGroupedByModule=$RegExCmdletMatches|Group-Object {$_.Groups['module'].Value}
            ForEach ($Module in $CommandsGroupedByModule) {
                $CommandsToPreLoad[$Module.Name]=$Module.Group|ForEach-Object{$_.Groups['command'].Captures.Value -Replace '[''"]','' -Split ','}|Select-Object -Unique
            }
        }

        # Now connect to the specified modules before preloading the commands
        $FatalError=$False
        Write-Progress -Activity $MainTitle -Status "Connecting modules" -PercentComplete 0
        $Current=0
        ForEach ($Module in ($CommandsToPreload.Keys|Sort-Object)) {
            Write-Progress -Activity $MainTitle -Status "Connecting modules [$($Current+1) of $($CommandsToPreLoad.Count)]" -CurrentOperation "Connecting to module $Module" -PercentComplete ([int](($Current/$CommandsToPreLoad.Count)*100))
            $ConnectModulePath=".\ConnectModules\$($Module).ps1"
            if (Test-Path $ConnectModulePath) {
                Write-Debug "Importing $Module module file: $ConnectModulePath"
                . $ConnectModulePath
            } Else {
                Write-Error "Could not load connect module $ConnectModulePath. Exiting because of non-recoverable error."
                $FatalError=$True
            }
            $Current++
        }

        Write-Progress -Activity $MainTitle -Status 'Connecting external modules' -PercentComplete 0
        $Current=0
        $ConnectModulePath='.\ExternalModuleCalls'
        $ExternalModulesToLoad=@(Get-ChildItem (Join-Path $ConnectModulePath '*.ps1'))
        ForEach ($ExternalModule in $ExternalModulesToLoad) {
            Write-Progress -Activity $MainTitle -Status "Connecting external modules [$($Current+1) of $($ExternalModulesToLoad.Count)]" -CurrentOperation "Connecting to module $($ExternalModule.BaseName)" -PercentComplete ([int](($Current/$ExternalModulesToLoad.Count)*100))

            if (Test-Path $ExternalModule.FullName) {
                Write-Debug "Importing $($ExternalModule.BaseName) module file: $($ExternalModule.FullName)"
                . $ExternalModule.FullName
            } Else {
                Write-Error "Could not load connect module $($ExternalModule.FullPath). Exiting because of non-recoverable error."
                $FatalError=$True
            }
            $Current++
        }

        if (-not $FatalError) {
            # Preload the commands for each module
            Write-Progress -Activity $MainTitle -Status "Preloading input variables" -PercentComplete 0
            $Current=0
            ForEach ($Module in $CommandsToPreload.Keys) {
                Write-Progress -Activity $MainTitle -Status "Preloading module variables [$($Current+1) of $($CommandsToPreLoad.Count)]" -CurrentOperation "Preloading for module $Module" -PercentComplete ([int](($Current/$CommandsToPreLoad.Count)*100))
                $Current=0
                Write-Debug "Preloading $Module module commands"
                & "Invoke-$($Module)Commands" -CommandsToPreload $CommandsToPreload[$Module]
                $Current++
            }

            # Run the external modules
            Write-Progress -Activity $MainTitle -Status "Executing external modules" -PercentComplete 0
            $Current=0
            ForEach ($ExternalModule in $ExternalModulesToLoad) {
                Write-Progress -Activity $MainTitle -Status "Executing external modules [$($Current+1) of $($ExternalModulesToLoad.Count)]" -CurrentOperation "Invoking module $($ExternalModule.BaseName)" -PercentComplete ([int](($Current/$ExternalModulesToLoad.Count)*100))
                Write-Debug "Invoking external module: $($ExternalModule.BaseName)"
                . "Invoke-$($ExternalModule.BaseName)Module"
                $Current++
            }            

            # Run the defined tests
            Write-Progress -Activity $MainTitle -Status "Executing test scripts" -PercentComplete 0
            $Current=0
            ForEach ($TestDefinitionFile in $FilesInTestDefinitionFolder) {
                Write-Progress -Activity $MainTitle -Status "Executing test scripts [$($Current+1) of $($FilesInTestDefinitionFolder.Count)]" -CurrentOperation "Executing $TestDefinitionFile" -PercentComplete ([int](($Current/$FilesInTestDefinitionFolder.Count)*100))
                Write-Debug "Invoking script: $TestDefinitionFile"
                $Null=. $TestDefinitionFile
                $Current++
            }
        }
    }

    if ($Script:TestDefinitions|Where-Object {($null -ne $_.TestResult) -and $_.TestResult.Count -gt 0}) {
        # Generate HTML Output
        Write-Progress -Activity $MainTitle -Status "Generating HTML output"
        if ([string]::IsNullOrEmpty($TenantDomain)) {
            $TenantDomain='<<unknown>>'
        }
        $Tenant=($TenantDomain -split '\.')[0]
        $HTMLReport=New-HtmlOutput -InputObject ($Script:TestDefinitions|Sort-Object Control) -TenantDomain $TenantDomain

        # Write to file
        If([string]::IsNullOrEmpty($OutputPath)) {
            $OutputDirectory=(Resolve-Path '.').Path
            $ReportFileName="ATPBaseline-$($tenant)-$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            $OutputPath="$OutputDirectory\$ReportFileName"
        }

        $HTMLReport | Out-File -FilePath $OutputPath
        Write-Host "$(Get-Date) Complete! Output is in $OutputPath"

        if ($OutputRawResultsFile) {
            $JsonOutputPath=$OutputPath -replace '\.html$','.json'
            $GlobalVarsOutputPath=$OutputPath -replace '\.html$','.global.xml'
            $Script:TestDefinitions|Select-Object * -ExcludeProperty 'TestDefinitionFile'|ConvertTo-Json -Depth 10|Out-File -FilePath $JsonOutputPath
            $GlobalsOutput=@{}
            ForEach ($PreloadedCommand in $script:PreloadedCommands) {
                $GlobalsOutput[$PreloadedCommand]=(Get-Variable -Name $PreloadedCommand).Value
            }
            $GlobalsOutput|Export-CliXML -Path $GlobalVarsOutputPath
        }
        Invoke-Expression $OutputPath

        Write-Progress -Activity $MainTitle -Completed
    }
}

#Test-ATPBaseline

<#
Generate "action list"
 (gc .\ATPBaseline-cloudsquadnl-20200117.json |convertfrom-json)|select -expand TestResult |?{$_.Result -eq 'Fail'}|group {(([array]($_.PSObject.Properties))[0]).Name},{(([array]($_.PSObject.Properties))[0]).Value} |%{$_.group |ft -a}
#>