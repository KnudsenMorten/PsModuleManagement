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
    $global:ModuleRequiredVersion = "2.32.0"

    If ([version]$Global:InstalledVersionMainModule.Version -gt [version]$global:ModuleRequiredVersion )
        {
            write-host "Downgrade manually to $($global:ModuleRequiredVersion) ... Please Wait !!"
            write-host ""
            
            # Force Microsoft Graph Authentication removal
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Remove-Module Microsoft.Graph.Authentication -Force -ErrorAction SilentlyContinue
            Uninstall-Module Microsoft.Graph.Authentication -AllVersions -Force

            # Force remove file in use
            $graphPaths = Get-Module Microsoft.Graph.Authentication -ListAvailable |
                          Select-Object -ExpandProperty Path

            $versionFolders = $graphPaths | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique

            $versionFolders | ForEach-Object {

                $folder = $_
                $folderVersion = Split-Path $folder -Leaf

                if ($folderVersion -eq $global:ModuleRequiredVersion) {
                    Write-Host "Skipping required version folder: $folder"
                    return
                }

                Write-Host "Removing: $folder"
                Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
            }

            uninstall-module Microsoft.Graph.Beta -AllVersions -Force
            install-module Microsoft.Graph.Beta -RequiredVersion $global:ModuleRequiredVersion -Force

            $global:TerminateSession = $true
        }
