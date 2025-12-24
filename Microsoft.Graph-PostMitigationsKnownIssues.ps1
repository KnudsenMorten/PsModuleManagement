#-----------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------
    $global:TerminateSession = $false

#-----------------------------------------------------------------------------------------------------------------
# Mitigations
#-----------------------------------------------------------------------------------------------------------------

    # Forcing a maximum/specific version
    Write-host "Version: $($Global:InstalledVersionMainModule.Version)"
    write-host ""

    # Forcing a maximum/specific version
    $global:ModuleRequiredVersion = "2.33.0"

    Write-host "Version: $($Global:InstalledVersionMainModule.Version)"
    write-host ""

    If ([version]$Global:InstalledVersionMainModule.Version -gt [version]$global:ModuleRequiredVersion )
        {
            write-host "Downgrade manually to v2.33.0 ... Please Wait !!"
            write-host ""
            
            uninstall-module Microsoft.Graph
            install-module Microsoft.Graph -RequiredVersion 2.33.0 -Force

            $global:TerminateSession = $true
        }