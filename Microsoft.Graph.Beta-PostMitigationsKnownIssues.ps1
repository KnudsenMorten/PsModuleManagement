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
    $global:ModuleRequiredVersion = "2.32"

    Write-host "Version: $($Global:InstalledVersionMainModule.Version)"
    write-host ""

    If ([version]$Global:InstalledVersionMainModule.Version -gt [version]$global:ModuleRequiredVersion )
        {
            write-host "Downgrade manually to $($global:ModuleRequiredVersion) ... Please Wait !!"
            write-host ""
            
            # Force Microsoft Graph Authentication removal
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Remove-Module Microsoft.Graph.Authentication -Force -ErrorAction SilentlyContinue
            Uninstall-Module Microsoft.Graph.Authentication -AllVersions -Force

            uninstall-module Microsoft.Graph.Beta -AllVersions -Force
            install-module Microsoft.Graph.Beta -RequiredVersion $global:ModuleRequiredVersion -Force

            $global:TerminateSession = $true
        }
