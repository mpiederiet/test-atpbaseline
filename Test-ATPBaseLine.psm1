#Requires -Module 'PackageManagement','DnsClient','PowerShellGet'
Set-StrictMode -version latest
Set-PSdebug -Strict
[Version]$Script:TestATPBaselineVersion='1.0'
[Version]$Script:BasedOnORCAVersion='1.3.2'
$Script:PreloadedCommands=New-Object System.Collections.ArrayList
$Script:TestDefinitions=New-Object System.Collections.ArrayList

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
    [String]$Area
    [String]$PassText
    [String]$FailRecommendation
    [String]$Importance
    [object[]]$TestResult
    [HashTable]$Links
    ATPBaselineCheck () {
        Add-Member -InputObject $This -MemberType 'ScriptProperty' -Name 'CheckResult' -Value {
            # If there are no testresults, or it is a single boolean '$False', or when at least one 'Fail' entry is present, mark the test as failed
            if (($this.TestResult.Count -eq 0) -or ($this.TestResult[0] -is [bool] -and -not $This.TestResult[0]) -or ($this.TestResult|Where-Object{($null -ne $_ -and $Null -ne $_.PSObject.Properties['Result'] -and $_.Result -eq 'Fail')})) {
                return 'Fail'
            } Else {
                return 'Pass'
            }
        }
    }
}

function Add-TestDefinition ($TestDefinition) {
    $Null=$Script:TestDefinitions.Add($TestDefinition)
}

function Test-ORCAVersion {
    # Check the Gallery version of ORCA
    Write-Debug "Performing ORCA Version check"

    $PSGalleryVersion=(Find-Module ORCA -Repository PSGallery -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue -Verbose:$False).Version

    Return $PSGalleryVersion
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
    $Form.Size = New-Object System.Drawing.Size(300,200)
    $Form.StartPosition = 'CenterScreen'

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(70,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $Form.AcceptButton = $OKButton
    $Form.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(160,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $Form.CancelButton = $CancelButton
    $Form.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = $Explanation
    $Form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.CheckedListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(260,20)
    $listbox.CheckOnClick = $True

    [void] $listBox.Items.AddRange($ListItems)

    # look for the default item and check it by default
    $ItemIndex=$ListBox.FindString($DefaultItem)
    if ($ItemIndex -ne -1) {
        $ListBox.SetItemChecked($ItemIndex,$true)
    }

    $listBox.Height = 70
    $Form.Controls.Add($listBox)
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
    $RecommendationCount=($InputObject | Where-Object {$_.CheckResult -eq 'Fail'}|Measure-Object).Count
    $OKCount=($InputObject | Where-Object {$_.CheckResult -eq 'Pass'}|Measure-Object).Count

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
    $output="<!doctype html>
<html lang='en'>
    <head>
        <!-- Required meta tags -->
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>
        <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/css/all.min.css' crossorigin='anonymous'>
        <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css' integrity='sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T' crossorigin='anonymous'>
        <script src='https://code.jquery.com/jquery-3.3.1.slim.min.js' integrity='sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo' crossorigin='anonymous'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js' integrity='sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1' crossorigin='anonymous'></script>
        <script src='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js' integrity='sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM' crossorigin='anonymous'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.11.2/js/all.js'></script>
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
                        <p>This report details any tenant configuration changes recommended within your tenant.</p>
                    </div>
                </div>`r`n"
    <#
        OUTPUT GENERATION / Summary cards
    #>
    $Output+=@"
                <div class='row p-3'>
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
        $Pass=@($Area.Group | Where-Object {$_.CheckResult -eq 'Pass'}).Count
        $Fail=@($Area.Group | Where-Object {$_.CheckResult -ne 'Pass'}).Count
        $Icon=$AreaIcon[$Area.Name]
        If($Null -eq $Icon) { $Icon=$AreaIcon["Default"]}

        $Output+=@"
                            <tr>
                                <td width='20'><i class='$Icon'></i>
                                <td><a href='`#$($Area.Name)'>$($Area.Name)</a></td>
                                <td align='right'>
                                <span class='badge badge-warning' style='padding:15px'>$($Fail)</span>
                                <span class='badge badge-success' style='padding:15px'>$($Pass)</span>
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
            If($Check.CheckResult -eq 'Pass') {
                $CalloutType='bd-callout-success'
                $BadgeType='badge-success'
                $BadgeName='OK'
                $Icon='fas fa-thumbs-up'
                $Title=$Check.PassText
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
            If([bool]::TryParse($Check.TestResult,[ref]$TestBool) -ne $True) {
                # make a new table for each object type in the test result set
                $GroupedByColumnHeader=$Check.TestResult | Group-Object {(([array]($_.PSObject.Properties))[0]).Name},{(([array]($_.PSObject.Properties))[1]).Name}
                $Output+=@"
                                <h6>Effected objects</h6>
                                <div class='row pl-2 pt-3'>`r`n
"@
                ForEach ($ColumnGroup in $GroupedByColumnHeader) {
                    # We should expand the results by showing a table of Config Data and Items
                    # First, determine the number of properties. 'Result' is assumed to always be present and is the last column of the table
                    $ColumnCount=([array]($ColumnGroup.Group[0].psobject.properties)|Where-Object {$_.MemberType -eq 'NoteProperty'}).count
                    $Output+=@"
                                    <table class='table'>
                                        <thead class='border-bottom'>
                                            <tr>`r`n
"@
                    0..($ColumnCount-2)|ForEach-Object{
                        $Output+=@"
                                                <th>$(([array]($ColumnGroup.Group[0].PSObject.Properties))[$_].Name)</th>`r`n
"@
                    }
                    $Output+=@"
                                                <th style='width:50px'></th>
                                            </tr>
                                        </thead>
                                        <tbody>`r`n
"@
                    ForEach($o in $ColumnGroup.Group) {
                        if($o.Result -eq "Pass") {
                            $oicon="fas fa-check-circle text-success"
                        } Else{
                            $oicon="fas fa-times-circle text-danger"
                        }
                        $Output+=@"
                                            <tr>`r`n
"@
                        0..($ColumnCount-2)|ForEach-Object{
                            $Output+=@"
                                                <td>$(([array]($o.PSObject.Properties))[$_].Value)</td>`r`n
"@
                        }
                        $Output+=@"
                                                <td><i class='$($oicon)'></i></td>
                                            </tr>`r`n
"@
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
    # The ORCA checks in this module are based on the ORCA PSGallery module. If there is a newer version available, make sure that the definitions used are kept up to date by the author ;-)
    Write-Progress -Activity $MainTitle -Status 'Checking ORCA version'
    $ORCAGalleryVersion=Test-ORCAVersion
    If ($ORCAGalleryVersion -gt $BasedOnORCAVersion) {
        Write-Warning "The definitions in this module are based on ORCA version $BasedOnORCAVersion. However there seems to be a newer ORCA module $($ORCAGalleryVersion). Please check whether there is an update for this module too."
    }

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
        $FilesInTestDefinitionFolder=Get-ChildItem '.\TestDefinitions\*.ps1'|Select-Object -Expand FullName
        Write-Verbose "$(Get-Date) TestDefinitions folder has $($FilesInTestDefinitionFolder.Count) test definition files"

        Write-Progress -Activity $MainTitle -Status "Looking for commands to preload"
        # Parse the headers of the .ps1 files, look for #InputRequired and a comma-delimited list of Module:Command to be preloaded
        $RegExCmdletMatches=(Select-String -Pattern '^#InputRequired ([''"]?(?<module>[a-zA-Z0-9]+):(?<command>[a-zA-Z0-9/]+)[''"]?(?:,[''"]?(?<module>[a-zA-Z0-9]+):(?<command>[a-zA-Z0-9/]+)[''"]?)*)' $FilesInTestDefinitionFolder|Select-Object -Expand matches)
        $CommandsGroupedByModule=$RegExCmdletMatches|Group-Object {$_.Groups['module'].Value}
        $CommandsToPreload=@{}
        ForEach ($Module in $CommandsGroupedByModule) {
            $CommandsToPreLoad[$Module.Name]=$Module.Group|ForEach-Object{$_.Groups['command'].Captures.Value -Replace '[''"]','' -Split ','}|Select-Object -Unique
        }

        # Now connect to the specified modules before preloading the commands
        $FatalError=$False
        Write-Progress -Activity $MainTitle -Status "Connecting external modules" -PercentComplete 0
        $Current=0
        ForEach ($Module in ($CommandsToPreload.Keys|Sort-Object)) {
            Write-Progress -Activity $MainTitle -Status "Connecting external modules [$($Current+1) of $($CommandsToPreLoad.Count)]" -CurrentOperation "Connecting to module $Module" -PercentComplete ([int](($Current/$CommandsToPreLoad.Count)*100))
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

    if ($Script:TestDefinitions|Where-Object {$_.TestResult.Count -gt 0}) {
        # Generate HTML Output
        Write-Progress -Activity $MainTitle -Status "Generating HTML output"
        $Tenant=(($Script:AcceptedDomain | Where-Object {$_.InitialDomain -eq $True}).DomainName -split '\.')[0]
        $HTMLReport=New-HtmlOutput -InputObject ($Script:TestDefinitions|Sort-Object Control) -TenantDomain $Tenant

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