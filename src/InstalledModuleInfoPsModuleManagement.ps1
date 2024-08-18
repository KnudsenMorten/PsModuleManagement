Function InstalledModuleInfoPsModuleManagement
{
    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$MainModule,
            [Parameter()]
                [string]$AuthModule,
            [Parameter()]
                [array]$MaintenancePowershellServices,
            [Parameter()]
                [array]$MaintenancePowershellProcesses,
            [Parameter()]
                [switch]$GetOldVersions,
            [Parameter()]
                [switch]$CheckInstallation

         )

    If ($CheckInstallation)
        {
            # Checking if Main module is installed ... Otherwise it will install it
                write-host ""
                write-host "Installation: Checking installation of main module $($MainModule) ... Please Wait !"
                $Global:InstalledVersionMainModule = Get-installedmodule $MainModule -ErrorAction SilentlyContinue

            # Installing Main module if not found !
                If (!($Global:InstalledVersionMainModule))
                    {
                        # Stopping all services
                            PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP

                        # install module
                            write-host ""
                            write-host "Installing module $($MainModule) as it wasn't found ... Please Wait !"
                            Try
                                {
                                    install-module $MainModule -force -Scope AllUsers -AllowClobber -ErrorAction Stop
                                }
                            Catch
                                {
                                    Try
                                        {
                                            install-module $MainModule -force -Scope AllUsers -ErrorAction Stop
                                        }
                                    Catch
                                        {
                                            write-host ""
                                            write-host "Errors occured .... terminating as modules are locked in memory !!"
                                            write-host "Close down the current Powershell session and re-run this script !"
                                            Exit 1
                                        }
                                }
                    }

            # Verify critical Auth component exists ! If not, then install component
                write-host ""
                write-host "Installation: Checking installation of authentication module $($AuthModule) ... Please Wait !"
                $AuthModuleInfo = Get-installedmodule $AuthModule -ErrorAction SilentlyContinue
                If (!($AuthModuleInfo))
                    {
                        # Stopping all services
                            PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP

                            Try
                                {
                                    install-module $AuthModule -force -Scope AllUsers -AllowClobber -ErrorAction Stop
                                }
                            Catch
                                {
                                    Try
                                        {
                                            install-module $AuthModule -force -Scope AllUsers -ErrorAction Stop
                                        }
                                    Catch
                                        {
                                            write-host "Errors occured .... terminating as modules are locked in memory !!"
                                            write-host "Close down the current Powershell session and re-run this script !"
                                            Exit 1
                                        }
                                }
                    }
        } # If ($CheckInstallation)

    # Get info about current version of Main Module
        write-host ""
        write-host "Getting info about current version of $($MainModule) ... Please Wait !"
        $Global:InstalledVersionMainModule = Get-installedmodule $MainModule

        If ($Global:InstalledVersionMainModule)
            {
                write-host ""
                write-host "Installed: Version of $($MainModule) found on system: $($Global:InstalledVersionMainModule.Version)"
            }
        Else
            {
                write-host ""
                write-host "Could not detect $($MainModule) on system .... exiting !"
                Exit 1
            }

        $Global:CurrentInstalledVersion = $InstalledVersionMainModule.Version

    # Getting information about Sub modules
        write-host ""
        write-host "Getting info about sub modules of $($MainModule) ... Please Wait !"
        $Global:InstalledVersionSubModules = Get-installedmodule "$($MainModule).*" -ErrorAction SilentlyContinue

    # Getting information about Auth Module
        $AuthModuleInfo = $InstalledVersionSubModules | Where-Object { $_.name -eq $AuthModule }
        $Global:AuthModuleRequiredVersion = $AuthModuleInfo.Version

        If ($Global:AuthModuleRequiredVersion)
            {
                write-host ""
                write-host "Installed: Version of $($AuthModule) found on system: $($Global:AuthModuleRequiredVersion)"
            }
        Else
            {
                write-host ""
                write-host "Could not detect $($AuthModule) on system .... exiting !"
                Exit 1
            }


    If ($GetOldVersions)
        {
            # Getting information about other versions of main module
                write-host ""
                write-host "Getting info about all versions of main module $($MainModule) on local system ... Please Wait !"
                $Global:InstalledAllVersionsMainModule = Get-installedmodule $MainModule -AllVersions -ErrorAction SilentlyContinue

            # Old Installed Version(s)
                $Global:OldInstalledVersionsMainModule = $InstalledAllVersionsMainModule | Where-Object { ([version]$_.Version -ne [version]$InstalledVersionMainModule.Version) -and ($_.Name -eq $InstalledVersionMainModule.Name) }
                If ($Global:OldInstalledVersionsMainModule)
                    {
                        write-host ""
                        write-host "Building overview of old installed modules of $($MainModule) ... Please Wait !"

                        $Global:OldInstalledVersionsSubModules = @()
                        ForEach ($Module in $Global:InstalledVersionSubModules)
                            {
                                $Global:OldInstalledVersionsSubModules += $Global:InstalledAllVersionsSubModules | Where-Object { ([version]$_.Version -ne [version]$Module.Version) -and ($_.Name -eq $Module.Name) }
                            }
                    }
        }
}
