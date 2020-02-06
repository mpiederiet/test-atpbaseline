#Requires -Module 'PackageManagement','PowerShellGet','Microsoft.Graph.Intune'
$Script:IntuneGraphAuthentication=$null
function Get-IntuneGraphConnectionStatus {
    Return ($null -ne $Script:IntuneGraphAuthentication)
}

function Invoke-IntuneGraphConnection {
    if(-not $Script:IntuneGraphAuthentication) {
        if((Get-Command Connect-MSGraph)) {
            $Script:IntuneGraphAuthentication = Connect-MSGraph -PassThru 
        }
    }

    if(-not $Script:IntuneGraphAuthentication) {
        Write-Error 'Failed to connect to Azure with Intune PowerShell module! No Intune extensions will be imported'
        return
    }

    $Script:Me = Invoke-GraphRequest "Me"

    if(-not $Script:Me) {
        Write-Error 'Failed to get information about current logged on Azure user! Verify connection and try again. No Intune modules will be imported'
        return
    }
    $Script:Organization = (Invoke-GraphRequest "Organization").Value
}

function Invoke-GraphRequest {
    param (
            [Parameter(Mandatory)]
            $Url,
            $Content,
            $Headers,
            [ValidateSet("GET","POST","OPTIONS","DELETE", "PATCH")]
            $HttpMethod = "GET"
        )

    $params = @{}
    
    $graphURL = "https://graph.microsoft.com/beta"

    if($Content) { $params.Add("Content", $Content) }
    if($Headers) { $params.Add("Headers", $Headers) }

    if(($Url -notmatch "^http://|^https://")) {
        $Url = $graphURL + "/" + $Url.TrimStart('/')
    }

    # Don't handle exceptions here, but handle them in the calling function
    Invoke-MSGraphRequest -Url $Url -HttpMethod $HttpMethod.ToUpper() @params
}

Function Invoke-IntuneGraphCommands([string[]]$CommandsToPreload) {
    Write-Verbose "$(Get-Date) Caching Intune Graph configuration information for $($CommandsToPreload.Count) cmdlets"

    ForEach ($GraphModuleToLoad in $CommandsToPreload) {
        Write-Verbose "$(Get-Date) Invoking $GraphModuleToLoad"
        $VariableName=($GraphModuleToLoad.TrimStart('/') -replace '/','_')
        Remove-Variable -scope 'Script' -Name $VariableName -ErrorAction SilentlyContinue
        try {
            New-Variable -scope 'Script' -Name $VariableName -Value (Invoke-GraphRequest -Url $GraphModuleToLoad).Value
        }
        catch {
            # Handle 401 Unauthorized response
            if ($_.Exception.Message -match '^401') {
                Write-Warning "Could not connect to Graph endpoint $GraphModuleToLoad. Please ensure you have the proper permissions to run this report."
                New-Variable -Scope 'Script' -Name $VariableName -Value @()            
            } Else {
                Throw $_
            }
        }
        $Null=$script:PreloadedCommands.Add($VariableName)
    }
}

# Connect to MS Graph
If ((Get-IntuneGraphConnectionStatus) -eq $False) {
    Invoke-IntuneGraphConnection
}