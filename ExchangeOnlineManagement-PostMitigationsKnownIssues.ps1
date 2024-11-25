#-----------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------
    $global:TerminateSession      = $false

#-----------------------------------------------------------------------------------------------------------------
# Mitigations
#-----------------------------------------------------------------------------------------------------------------

    # Forcing a maximum/specific version
    $global:ModuleRequiredVersion = "3.6.0"

    Write-host "Version: $($Global:InstalledVersionMainModule.Version)"
    write-host ""

    If ([version]$Global:InstalledVersionMainModule.Version -gt [version]$global:ModuleRequiredVersion )
        {
            write-host "Downgrade manually to v3.6.0 ... Please Wait !!"
            write-host ""
            
            uninstall-module ExchangeOnlineManagement
            install-module ExchangeOnlineManagement -RequiredVersion 3.6 -Force

            $global:TerminateSession = $true
        }
