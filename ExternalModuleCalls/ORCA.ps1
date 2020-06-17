#Requires -module ORCA
# Import latest classes from ORCA module
$ORCA=Get-module -ListAvailable ORCA
if ($ORCA) {
    # First import the module, because the "Using module" statement below will otherwise break the ORCA version check
    $ORCAModule=Import-Module ORCA -PassThru
    # Use latest version
    $ORCAPath=$ORCA | Sort-Object version -Descending | Select-Object -first 1 -ExpandProperty ModuleBase
    $ORCAModuleFile=Join-path $ORCAPath 'ORCA.psm1'
    # "Using module" does not accept variables, using this scriptblock workaround
    $scriptBody = "using module '$ORCAModuleFile'"
    $script = [ScriptBlock]::Create($scriptBody)
    . $script
}
[Version]$Script:BasedOnORCAVersion='1.8.8'

function Get-EXOConnectionStatus
{
    # Perform check to determine if we are connected
    Try {
        Get-Mailbox -ResultSize:1 -WarningAction:SilentlyContinue | Out-Null
        Return $True
    }
    Catch {
        Return $False
    }
}

Function Invoke-EXOConnection {
    # Function taken from ORCA with one minor addition (-parametername 'PSSessionOption'), to prevent using Connect-EXOPSsession from the MSAPIConnect module 
    If(Get-Command "Connect-EXOPSSession" -parametername 'PSSessionOption' -ErrorAction:SilentlyContinue)
    {
        Write-Verbose "$(Get-Date) Connecting to Exchange Online.."
        Connect-EXOPSSession -PSSessionOption $ProxySetting -WarningAction:SilentlyContinue  -Verbose:$False| Out-Null
    } 
    ElseIf(Get-Command "Connect-ExchangeOnline" -ErrorAction:SilentlyContinue)
    {
        Write-Verbose "$(Get-Date) Connecting to Exchange Online (Modern Module).."
        Connect-ExchangeOnline -WarningAction:SilentlyContinue -Verbose:$False | Out-Null
    }
    Else 
    {
        Throw "$(Split-Path -Leaf $MyInvocation.ScriptName) requires either the Exchange Online PowerShell Module (aka.ms/exopsmodule) loaded or the Exchange Online PowerShell module from the PowerShell Gallery installed."
    }

    # Perform check for Exchange Connection Status
    If($(Get-EXOConnectionStatus) -eq $False) {
        Throw "Test-ATPBaseline was unable to connect to Exchange Online."
    }
}

Function Invoke-ORCAModule {
    Write-Verbose "$(Get-Date) Invoking ORCA and requesting JSON output"
    #Invoke ORCA report
    $ORCACallResult=. $ORCAModule {Invoke-ORCA -Output JSON}

    if ($Null -ne $ORCACallResult -and $ORCACallResult.Completed) {
        #Parse JSON results, convert into Test-ATPBaseline supported output
        $ResultFile=Get-Content $ORCACallResult.Result
        if ($ResultFile) {
            try {
                $ORCAResults=$ResultFile|ConvertFrom-Json
            }
            catch {
                Throw "Test-ATPBaseline was unable to convert the ORCA results to JSON. Error: $($Error[0].Message)"
            }
            if ([string]::IsNullOrEmpty($TenantDomain) -and -not [string]::IsNullOrEmpty($ORCAResults.Tenant)) {
                $Script:TenantDomain="$($ORCAResults.Tenant).onmicrosoft.com"
            }
            $ORCAResults=$ORCAResults.Results
            $CompletedResults=$ORCAResults|Where-Object{$_.Completed}
            # Create a Hashtable, which will be used later on to typecast to a ATPBaselineCheck object
            $ReturnHash=[ordered]@{}
            ForEach ($ORCAResult in $CompletedResults) {
                # Ensure all controls are prepended with "ORCA-"
                if ($ORCAResult.Control -notmatch '^ORCA\-') {
                    $ORCAResult.Control="ORCA-$($ORCAResult.Control)"
                }
                $ReturnHash['Name']=$ORCAResult.Name
                $ReturnHash['Control']=$ORCAResult.Control
                $ReturnHash['TestDefinitionFile']='EXTERNAL-ORCA'
                # ORCA Services EOP and OATP map directly to BaseLineCheckServices EOP and OfficeATP
                $ReturnHash['Services']=$ORCAResult.Services
                $ReturnHash['Area']=$ORCAResult.Area
                $ReturnHash['PassText']=$ORCAResult.PassText
                $ReturnHash['FailRecommendation']=$ORCAResult.FailRecommendation
                $ReturnHash['Importance']=$ORCAResult.Importance
                if ($ORCAResult.Links) {
                    $ReturnHash['Links']=$ORCAResult.Links|ConvertTo-HashTable
                } Else {
                    $ReturnHash['Links']=@{}
                }
                $TestResultCollection=New-Object System.Collections.ArrayList
                if ($ORCAResult.ExpandResults) {
                    ForEach ($CheckConfig in ([ORCACheckConfig[]]($ORCAResult.Config))) {
                        $TestResultItem=[ordered]@{}
                        if ($CheckConfig.Level -eq [ORCAConfigLevel]::Informational) {
                            $TestResultItem['__InfoText']=$CheckConfig.InfoText
                        }
                        # Add result objects to the collection, using the specified column names
                        if ($ORCAResult.CheckType -eq [CheckType]::ObjectPropertyValue) {
                            $TestResultItem[$ORCAResult.ObjectType]=$CheckConfig.Object
                        }
                        $TestResultItem[$ORCAResult.ItemName]=$CheckConfig.ConfigItem
                        $TestResultItem[$ORCAResult.DataType]=$CheckConfig.ConfigData
                        $TestResultItem['__Level']=[BaseLineCheckLevel]([ORCAConfigLevel]$CheckConfig.Level)
                        $null=$TestResultCollection.Add($TestResultItem)
                    }
                } Else {
                    $TestResultItem=[ordered]@{}
                    $TestResultItem['__TestResult']=($ORCAResult.Result -eq [ORCAResult]::Pass)
                    $null=$TestResultCollection.Add($TestResultItem)
                }
                $ReturnHash['TestResult']=$TestResultCollection
                $TestDefinition=[ATPBaselineCheck]$ReturnHash
                Add-TestDefinition -TestDefinition $TestDefinition
            }
        }
    }
}

function Test-ORCAVersion {
    # Check the Gallery version of ORCA
    Write-Debug "Performing ORCA Version check"

    $PSGalleryVersion=(Find-Module ORCA -Repository PSGallery -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue -Verbose:$False).Version

    Return $PSGalleryVersion
}


# The ORCA checks in this module are based on the ORCA PSGallery module. If there is a newer version available, make sure that the definitions used are kept up to date by the author ;-)
Write-Progress -Activity $MainTitle -Status 'Checking ORCA version'
$ORCAGalleryVersion=Test-ORCAVersion
If ($ORCAGalleryVersion -gt $BasedOnORCAVersion) {
    Write-Warning "The definitions in this module are based on ORCA version $BasedOnORCAVersion. However there seems to be a newer ORCA module $($ORCAGalleryVersion). Please check whether there is an update for this module too."
}

# Connect to Exchange Online
If ((Get-EXOConnectionStatus) -eq $False) {
    Invoke-EXOConnection
}