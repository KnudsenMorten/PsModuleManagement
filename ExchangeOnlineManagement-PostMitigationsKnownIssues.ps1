#-----------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------
    $global:TerminateSession      = $false
    $global:ModuleRequiredVersion = "3.4"

#-----------------------------------------------------------------------------------------------------------------
# Mitigations
#-----------------------------------------------------------------------------------------------------------------

    
    # The issue is that ExchangeOnlineManagement 3.5.1 uses version 8.0.23.53103 of System.Text.Json.dll 
    # where 3.4.x doesn't use System.Text.Json.dll at all, hence there's no conflict with 
    # version 6.0.21.52210 used by the Microsoft.Graph.Authentication module.

    If ([version]$Global:InstalledVersionMainModule.Version -ge [version]3.5.0 )
        {
            write-host "Downgrade manually to v3.4 ... Please Wait !!"
            write-host ""
            write-host "Reason:"
            write-host "ExchangeOnlineManagement 3.5.1 uses version 8.0.23.53103 of System.Text.Json.dll"
            write-host "where 3.4.x doesn't use System.Text.Json.dll at all, hence there's no conflict with"
            write-host "version 6.0.21.52210 used by the Microsoft.Graph.Authentication module."
            write-host ""
            # uninstall-module ExchangeOnlineManagement
            # install-module ExchangeOnlineManagement -RequiredVersion 3.4 -Force

            $global:TerminateSession = $true
        }

