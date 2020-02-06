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

Function Invoke-EXOCommands([string[]]$CommandsToPreload) {
    Write-Verbose "$(Get-Date) Caching EXO configuration information for $($CommandsToPreload.Count) cmdlets"
    ForEach ($CmdletToLoad in $CommandsToPreload) {
        Write-Verbose "$(Get-Date) Invoking Get-$CmdletToLoad"
        Remove-Variable -Scope 'Script' -Name $CmdletToLoad -ErrorAction SilentlyContinue
        try {
            New-Variable -Scope 'Script' -Name $CmdletToLoad -Value (Invoke-Expression "Get-$CmdletToLoad")
        }
        catch {
            if ($_.Exception -is [System.Management.Automation.CommandNotFoundException]) {
                Write-Warning "Could not execute EXO command Get-$($CmdletToLoad). Please ensure you have the proper permissions to run this report."
                New-Variable -Scope 'Script' -Name $CmdletToLoad -Value @()
            } Else {
                Throw $_
            }
        }
        $Null=$script:PreloadedCommands.Add($CmdletToLoad)
    }
}

# Connect to Exchange Online
If ((Get-EXOConnectionStatus) -eq $False) {
    Invoke-EXOConnection
}
