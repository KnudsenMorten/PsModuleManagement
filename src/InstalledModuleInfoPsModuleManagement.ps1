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
                [switch]$CheckInstallation,
            [Parameter()]
    [AllowEmptyString()]
           [AllowNull()]
                [string]$ModuleRequiredVersion,
    [AllowEmptyString()]
           [AllowNull()]
                [string]$AuthModuleRequiredVersion,
    [AllowEmptyString()]
           [AllowNull()]
                [array]$RequiredModules
         )

<#
    $MainModule                        = "Microsoft.Graph"
    $AuthModule                        = "Microsoft.Graph.Authentication"
    $ModuleRequiredVersion             = $null
    $MaintenancePowershellServices     = @("VisualCron")
    $MaintenancePowershellProcesses    = @("powershell","powershell_ise","VisualCronClient")
    $GetOldVersions                    = $true
#>

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
                                    If ($ModuleRequiredVersion)
                                        {
                                            install-module $MainModule -force -Scope AllUsers -RequiredVersion $ModuleRequiredVersion  -AllowClobber -ErrorAction Stop
                                        }
                                    Else
                                        {
                                            install-module $MainModule -force -Scope AllUsers -AllowClobber -ErrorAction Stop
                                        }
                                }
                            Catch
                                {
                                    Try
                                        {
                                            If ($ModuleRequiredVersion)
                                                {
                                                    install-module $MainModule -force -Scope AllUsers -RequiredVersion $ModuleRequiredVersion -ErrorAction Stop
                                                }
                                            Else
                                                {
                                                    install-module $MainModule -force -Scope AllUsers -ErrorAction Stop
                                                }
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
            If ($AuthModule)
                {
                    #--------------------------------------------------------------------------------------------
                    $AuthModules = Get-module $AuthModule -ErrorAction SilentlyContinue
                    #--------------------------------------------------------------------------------------------
                    write-host ""
                    write-host "Installation: Checking installation of authentication module $($AuthModule) ... Please Wait !"
                    $AuthModuleInfo = Get-installedmodule $AuthModule -ErrorAction SilentlyContinue
                    write-host "$($AuthModule) -> $($AuthModuleInfo.version)"
                    
                    If (!($AuthModuleInfo)) {
                        write-host "Re-install $($MainModule) (version: $($ModuleRequiredVersion)) as authentication module was not found !"
                        install-module $MainModule -force -Scope AllUsers -RequiredVersion $ModuleRequiredVersion -AllowClobber
                    }

                    # Remove auth. modul if newer !
                    If ( ($global:AuthModuleRequiredVersion) -and ([version]$AuthModuleInfo.Version -gt [version]$global:AuthModuleRequiredVersion ) ) {
                        write-host "Downgrade manually to $($global:AuthModuleRequiredVersion) ... Please Wait !!"
                        write-host ""
            
                        # Force auth removal
                        Remove-Module $AuthModule -Force -ErrorAction SilentlyContinue
                        Uninstall-Module $AuthModule -AllVersions -Force -ErrorAction SilentlyContinue

                        # Force remove file in use
                        $graphPaths = Get-Module $AuthModule -ListAvailable |
                                        Select-Object -ExpandProperty Path

                        $versionFolders = $graphPaths | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique

                        $versionFolders | ForEach-Object {

                            $folder = $_
                            $folderVersion = Split-Path $folder -Leaf

                            if ($folderVersion -eq $global:AuthModuleRequiredVersion) {
                                Write-Host "Skipping required version folder: $folder"
                                return
                            }

                            Write-Host "Removing: $folder"
                            Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
                        }

                        write-host "Installing $($global:AuthModuleRequiredVersion)"
                        install-Module $AuthModule -RequiredVersion $global:AuthModuleRequiredVersion -Force
                    }
                }

        } # If ($CheckInstallation)

    # RequiredModules
    If ($RequiredModules) {
        $ForceMainModuleRepair = $false

        ForEach ($Module in $RequiredModules) {
            write-host ""
            write-host "Validating critical module exist: $($Module)" 
            $ModuleChkAuthModuleInfo = Get-installedmodule $Module -ErrorAction SilentlyContinue
            If (!($ModuleChkAuthModuleInfo)) {
                write-host "$($Module) -> NOT FOUND - REPAIR REQUIRED!"
                $ForceMainModuleRepair = $true
            } Else {
                write-host "$($Module) -> $($ModuleChkAuthModuleInfo.version)"
            }
        }

        If ($ForceMainModuleRepair) {
            write-host ""
            write-host "Re-install $($MainModule) (version: $($ModuleRequiredVersion)) as required files were not detected !"
            install-module $MainModule -force -Scope AllUsers -RequiredVersion $ModuleRequiredVersion -AllowClobber
        }
    }


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
    If ($AuthModule)
        {
            $AuthModuleInfo = Get-installedmodule $AuthModule -ErrorAction SilentlyContinue
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
        }


    If ($GetOldVersions)
        {
            # Main Module - Getting information latest versions of main module
                write-host ""
                write-host "Getting info about all versions of main module $($MainModule) on local system ... Please Wait !"
                $InstalledAllMain = Get-module $MainModule -ListAvailable -ErrorAction SilentlyContinue

            # Sub modules - Getting information about latest installed version of sub-modules module
                write-host ""
                write-host "Getting info about sub modules of $($MainModule) ... Please Wait !"
                $InstalledAllSub = Get-module "$($MainModule).*" -ListAvailable -ErrorAction SilentlyContinue

            # Build $InstalledAllVersions array
                $InstalledAllVersions = @()

                If ($InstalledAllMain)
                    {
                        ForEach ($Entry in $InstalledAllMain)
                            {
                                $Object = New-Object PSObject
                                $Object | Add-Member -MemberType NoteProperty -Name "Name" -Value $Entry.Name
                                $Object | Add-Member -MemberType NoteProperty -Name "Version" -Value $Entry.Version
                                $InstalledAllVersions += $Object
                            }
                    }
                If ($InstalledAllSub)
                    {
                        ForEach ($Entry in $InstalledAllSub)
                            {
                                $Object = New-Object PSObject
                                $Object | Add-Member -MemberType NoteProperty -Name "Name" -Value $Entry.Name
                                $Object | Add-Member -MemberType NoteProperty -Name "Version" -Value $Entry.Version
                                $InstalledAllVersions += $Object
                            }
                    }

            If ($global:ModuleRequiredVersion)
                {
                    write-host ""
                    write-host "Getting latest versions incl. sub-modules ... Please Wait (slow) !"
                    $LatestVersions = Find-Module -Name $MainModule -Repository PSGallery -IncludeDependencies -RequiredVersion $global:ModuleRequiredVersion
                }
            Else
                {
                    write-host ""
                    write-host "Getting latest versions incl. sub-modules ... Please Wait (slow) !"
                    $LatestVersions = Find-Module -Name $MainModule -Repository PSGallery -IncludeDependencies
                }

            write-host ""
            write-host "Building overview of old installed modules of $($MainModule) ... Please Wait !"

            $Global:OldInstalledVersionsModules = @()
            ForEach ($Module in $LatestVersions)
                {
                    $Global:OldInstalledVersionsModules += $InstalledAllVersions | Where-Object { ([version]$_.Version -ne [version]$Module.Version) -and ($_.Name -eq $Module.Name) }
                }
        }
}
