#########################################################################################################
# Functions
#########################################################################################################

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
$Log = $ENV:Windir + "\TEMP\PowershellModuleManagement-log.txt"
Start-Transcript $Log
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Defaults
    $CriticalErrorsOccured = $false
    $MaximumFunctionCount = 32768

Function Update-PowershellModule
{
    [CmdletBinding()]
    param(

            [Parameter(mandatory)]
                [string]$ModuleName,
            [Parameter()]
                [ValidateSet("AllUsers","CurrentUser")]
                $Scope = "AllUsers"
         )

    $ModuleCheck = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
        If (!($ModuleCheck))
        {
            Write-host ""
            Write-host "Processing dependencies for module $($ModuleName) ... Please Wait !"

            # check for NuGet package provider
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            Write-host ""
            Write-host "Checking Powershell PackageProvider NuGet ... Please Wait !"
                if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 
                    {
                        Write-Host "OK - PackageProvider NuGet is installed"
                    } 
                else 
                    {
                        try
                            {
                                Write-Host "Installing NuGet package provider .. Please Wait !"
                                Install-PackageProvider -Name NuGet -Scope $Scope -Confirm:$false -Force
                            }
                        catch [Exception] {
                            $_.message 
                            exit
                        }
                    }

            Write-host ""
            Write-host "Installing latest version of $($ModuleName) from PsGallery in scope $($Scope) .... Please Wait !"

            Install-module -Name $ModuleName -Repository PSGallery -Force -Scope $Scope
            import-module -Name $ModuleName -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
        }
    Else
        {
            #####################################
            # Check for any available updates                    
            #####################################

                # Current version
                $InstalledVersions = Get-module $ModuleName -ListAvailable

                $LatestVersion = $InstalledVersions | Sort-Object Version -Descending | Select-Object -First 1

                # Online version in PSGallery (online)
                $Online = Find-Module -Name $ModuleName -Repository PSGallery

                # Compare versions
                if ( ([version]$Online.Version) -gt ([version]$LatestVersion.Version) ) 
                    {
                        Write-host ""
                        Write-host "Newer version ($($Online.version)) of $($ModuleName) was detected in PSGallery"
                        Write-host ""
                        Write-host "Updating to latest version $($Online.version) of $($ModuleName) from PSGallery ... Please Wait !"
                            
                        Update-module $ModuleName -Force
                        import-module -Name $ModuleName -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                    }
                Else
                    {
                        # No new version detected ... continuing !
                        Write-host ""
                        Write-host "OK - Running latest version ($($LatestVersion.version)) of $($ModuleName)"
                    }

            #####################################
            # Clean-up older versions, if found
            #####################################

                $CleanupVersions = $InstalledVersions | Where-Object { $_.Version -ne $LatestVersion.Version }

                Write-host ""
                ForEach ($ModuleRemove in $CleanupVersions)
                    {
                        Write-Host "Removing older version $($ModuleRemove.Version) of $($ModuleRemove.Name) ... Please Wait !"

                        Uninstall-module -Name $ModuleRemove.Name -RequiredVersion $ModuleRemove.Version -Force -ErrorAction SilentlyContinue
                    }
        }
}     

Function Resolve-PowershellModuleRequiredVersion
{
    [CmdletBinding()]
    param(
            [Parameter(Mandatory)]
                [string]$ModuleName,
            [Parameter()]
                [string]$RequiredVersion
         )

    If ([string]::IsNullOrWhiteSpace($RequiredVersion))
        {
            return $null
        }

    # Resolve aliases such as 3.6 to the exact PSGallery version string, e.g. 3.6.0.
    # System.Version treats 3.6 and 3.6.0 as different objects, so string/Version comparison can otherwise
    # misclassify an installed 3.6.0 as a non-locked version when the lock is written as 3.6.
    $OnlineExactVersion = Find-Module -Name $ModuleName -Repository PSGallery -RequiredVersion $RequiredVersion -ErrorAction SilentlyContinue

    If ($OnlineExactVersion)
        {
            return [string]$OnlineExactVersion.Version
        }

    return $RequiredVersion
}

Function Test-PowershellModuleVersionMatchesLock
{
    [CmdletBinding()]
    param(
            [Parameter(Mandatory)]
                [object]$InstalledVersion,
            [Parameter(Mandatory)]
                [string]$RequiredVersion
         )

    $InstalledVersionString = [string]$InstalledVersion
    $RequiredVersionString = [string]$RequiredVersion

    If ($InstalledVersionString -eq $RequiredVersionString)
        {
            return $true
        }

    # Accept shortened lock syntax only when the installed version has the same prefix and only trailing .0 components.
    # Example: lock 3.6 matches installed 3.6.0, but lock 3.6 does not match 3.6.1 or 3.60.0.
    If ($InstalledVersionString -match '^' + [regex]::Escape($RequiredVersionString) + '(\.0)+$')
        {
            return $true
        }

    return $false
}

Function Install-PowershellModuleExactOrLatest
{
    [CmdletBinding()]
    param(
            [Parameter(Mandatory)]
                [string]$ModuleName,
            [Parameter()]
                [string]$RequiredVersion,
            [Parameter()]
                [ValidateSet("AllUsers","CurrentUser")]
                [string]$Scope = "AllUsers"
         )

    If ([string]::IsNullOrWhiteSpace($RequiredVersion))
        {
            Write-host "Installing latest version of $($ModuleName) from PSGallery in scope $($Scope) .... Please Wait !"
            Install-Module -Name $ModuleName -Repository PSGallery -Force -Scope $Scope -AllowClobber -ErrorAction Stop
        }
    Else
        {
            $ResolvedRequiredVersion = Resolve-PowershellModuleRequiredVersion -ModuleName $ModuleName -RequiredVersion $RequiredVersion
            $InstalledExactVersion = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue | Where-Object { Test-PowershellModuleVersionMatchesLock -InstalledVersion $_.Version -RequiredVersion $ResolvedRequiredVersion } | Select-Object -First 1

            If ($InstalledExactVersion)
                {
                    Write-host "OK - Locked version $($ResolvedRequiredVersion) of $($ModuleName) is already installed - not reinstalling"
                    return
                }

            Write-host "Installing locked version $($ResolvedRequiredVersion) of $($ModuleName) from PSGallery in scope $($Scope) .... Please Wait !"
            Install-Module -Name $ModuleName -Repository PSGallery -RequiredVersion $ResolvedRequiredVersion -Force -Scope $Scope -AllowClobber -ErrorAction Stop
        }
}


Function Ensure-PowershellModuleRequiredVersion
{
    [CmdletBinding()]
    param(
            [Parameter(Mandatory)]
                [string]$ModuleName,
            [Parameter()]
                [string]$RequiredVersion,
            [Parameter()]
                [ValidateSet("AllUsers","CurrentUser")]
                [string]$Scope = "AllUsers"
         )

    If ([string]::IsNullOrWhiteSpace($RequiredVersion))
        {
            return
        }

    $ResolvedRequiredVersion = Resolve-PowershellModuleRequiredVersion -ModuleName $ModuleName -RequiredVersion $RequiredVersion
    $InstalledVersions = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
    $InstalledExactVersion = $InstalledVersions | Where-Object { Test-PowershellModuleVersionMatchesLock -InstalledVersion $_.Version -RequiredVersion $ResolvedRequiredVersion } | Select-Object -First 1

    If ($InstalledExactVersion)
        {
            Write-host "OK - Locked version $($ResolvedRequiredVersion) of $($ModuleName) is installed"
        }
    Else
        {
            Install-PowershellModuleExactOrLatest -ModuleName $ModuleName -RequiredVersion $ResolvedRequiredVersion -Scope $Scope
            $InstalledVersions = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue
        }

    # A locked module must not keep newer/older side-by-side versions.
    # PowerShell imports the newest installed version by default unless -RequiredVersion is used everywhere.
    $OtherInstalledVersions = $InstalledVersions | Where-Object { -not (Test-PowershellModuleVersionMatchesLock -InstalledVersion $_.Version -RequiredVersion $ResolvedRequiredVersion) }

    ForEach ($OtherVersion in $OtherInstalledVersions)
        {
            Write-host "Removing non-locked version $($OtherVersion.Version) of $($ModuleName) ... Please Wait !"
            Uninstall-Module -Name $ModuleName -RequiredVersion $OtherVersion.Version -Force -ErrorAction SilentlyContinue
        }
}


    $ModuleName = "PsModuleManagement"
    $Scope      = "AllUsers"
    Update-PowershellModule -ModuleName $ModuleName -Scope AllUsers
    Import-module PsModuleManagement -Global -force -DisableNameChecking

 
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##################################################################################################################################################################################
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$Modules = @(
                [PSCustomObject]@{
                                    MainModule                        = "ExchangeOnlineManagement"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "ExchangeOnlineManagement-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = "3.6.0"
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az"
                                    AuthModule                        = "Az.Accounts"
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.ConnectedMachine"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.Peering"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.DataProtection"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.ResourceGraph"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph"
                                    AuthModule                        = "Microsoft.Graph.Authentication"
                                    RequiredModules                   = @("Microsoft.Graph.Groups","Microsoft.Graph.Identity.SignIns")
                                    PostMitigationScriptKnownIssues   = "Microsoft_Graph-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = "2.32.0"
                                    AuthModuleRequiredVersion         = "2.32.0"
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph.Intune"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "Microsoft_Graph_Intune-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph.Beta"
                                    AuthModule                        = "Microsoft.Graph.Authentication"
                                    RequiredModules                   = @("Microsoft.Graph.Beta.Groups","Microsoft.Graph.Beta.Identity.SignIns")
                                    PostMitigationScriptKnownIssues   = "Microsoft_Graph_Beta-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = "2.32.0"
                                    AuthModuleRequiredVersion         = "2.32.0"
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "AzLogDcrIngestPS"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "AzLogDcrIngestPS-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "powershell-yaml"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "powershell-yaml-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "MicrosoftGraphPS"
                                    AuthModule                        = $null
                                    RequiredModules                   = @()
                                    PostMitigationScriptKnownIssues   = "MicrosoftGraphPS-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                    AuthModuleRequiredVersion         = $null
                                 }
            )

$ModulePos = 0
$ModulesTotal = $Modules.count

ForEach ($Module in $Modules)
    {

        $global:MainModule                        = $Module.MainModule
        $global:AuthModule                        = $Module.AuthModule
        $global:RequiredModules                   = $Module.RequiredModules
        $global:PostMitigationScriptKnownIssues   = $Module.PostMitigationScriptKnownIssues
        $global:ModuleRequiredVersion             = $Module.ModuleRequiredVersion
        $global:AuthModuleRequiredVersion         = $Module.AuthModuleRequiredVersion
        $ModulePos                                = 1 + $ModulePos
    
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # Start
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
            Write-host ""
            Write-host "---------------------------------------------------------------------------------------"
            Write-host ""
            write-host "Starting to manage $($MainModule) [ $($ModulePos) / $($ModulesTotal) ]"
            Write-host ""

        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # Check Installed versions
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
            InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses -CheckInstallation -ModuleRequiredVersion $ModuleRequiredVersion -AuthModuleRequiredVersion $AuthModuleRequiredVersion -RequiredModules $RequiredModules

            # Enforce locked versions explicitly. This prevents Microsoft.Graph dependencies from being pulled/kept at latest when the module is pinned.
                Ensure-PowershellModuleRequiredVersion -ModuleName $MainModule -RequiredVersion $ModuleRequiredVersion -Scope AllUsers

                If ($AuthModule)
                    {
                        Ensure-PowershellModuleRequiredVersion -ModuleName $AuthModule -RequiredVersion $AuthModuleRequiredVersion -Scope AllUsers
                    }

                ForEach ($RequiredModule in $RequiredModules)
                    {
                        Ensure-PowershellModuleRequiredVersion -ModuleName $RequiredModule -RequiredVersion $ModuleRequiredVersion -Scope AllUsers
                    }

            # Refresh module state after enforcing locked versions; InstalledModuleInfoPsModuleManagement sets globals such as $CurrentInstalledVersion.
                InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses -CheckInstallation -ModuleRequiredVersion $ModuleRequiredVersion -AuthModuleRequiredVersion $AuthModuleRequiredVersion -RequiredModules $RequiredModules

        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # PostActionsPsModuleManagement - Important after initial implementation
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------

            $Result = PostActionsPsModuleManagement -FileName $PostMitigationScriptKnownIssues -GitHubUri "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

            If ($global:TerminateSession)
                {
                    Write-host "Initial installation & post-actions requires the current session to be terminated and restarted !"
                    write-host "Close down the current Powershell session and re-run this script !"
                    Exit 1
                }

        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # Test if Module can connect, based on installed versions (fallback)
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------

            $ConnectivityErrorsDetected = $False

            If ( ($CurrentInstalledVersion) -and ($global:AuthModule) )
                {
                    $ConnectivityErrorsDetected = TestConnectivityPsModuleManagement -Entra_App_ApplicationID $Entra_App_ApplicationID `
                                                                                     -Entra_App_CertificateThumbprint $Entra_App_CertificateThumbprint `
                                                                                     -Entra_App_TenantID $Entra_App_TenantID `
                                                                                     -Entra_TenantName $Entra_TenantName `
                                                                                     -MainModule $MainModule `
                                                                                     -AuthModule $AuthModule `
                                                                                     -AuthModuleRequiredVersion $AuthModuleRequiredVersion `
                                                                                     -AzSubscriptionId $AzSubscriptionId
                }

        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # Connectivity works with current version
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        If ( (!($ConnectivityErrorsDetected)) -and ($global:AuthModule) )
            {
                $ConnectivityInstalledVersions = "SUCCESS"

                SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsSuccess `
                                                        -SMTP_Host $SMTP_Host `
                                                        -SMTP_UserId $SMTP_UserId `
                                                        -SMTP_Password $SMTP_Password `
                                                        -SMTP_Port $SMTP_Port `
                                                        -SMTP_From $SMTP_From `
                                                        -SMTP_To $SMTP_To `
                                                        -SMTP_Subject "[$($Description)] SUCCESS: $($MainModule) version: $($CurrentInstalledVersion) is working" `
                                                        -SMTP_Body "<font color=black>$($MainModule) is working on $($Description)</font><br><br>" `
                                                        -Description $Description `
                                                        -UseSSL $global:SMTP_UseSSL
            }

        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        # Errors detected with installed version - lets try to uninstall current main-module !
        #-----------------------------------------------------------------------------------------------------------------------------------------------------------
        ElseIf ( ($ConnectivityErrorsDetected) -and ($global:AuthModule) )
            {
                $ConnectivityInstalledVersions = "CRITICAL"
            
                SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                        -SMTP_Host $SMTP_Host `
                                                        -SMTP_UserId $SMTP_UserId `
                                                        -SMTP_Password $SMTP_Password `
                                                        -SMTP_Port $SMTP_Port `
                                                        -SMTP_From $SMTP_From `
                                                        -SMTP_To $SMTP_To `
                                                        -SMTP_Subject "[$($Description)] CRITICAL: $($MainModule) versions seems broken - Complete Re-installation in progress" `
                                                        -SMTP_Body "<font color=red>Complete $($MainModule) re-installation will now be tried on $($Description) as no working $($MainModule) versions were found</font><br><br>" `
                                                        -Description $Description `
                                                        -UseSSL $global:SMTP_UseSSL

                # Re-installing current Main module to try to fix current state!
                    If ($Global:InstalledVersionMainModule)
                        {
                            Write-host ""
                            Write-host "Errors detected .. Re-installing version $($Global:InstalledVersionMainModule.version) of $($MainModule) ... Please Wait !"

                            # Stopping all services
                                PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP

                            # Re-installing current Main module to try to fix current state!
                                Try
                                    {
                                        Install-PowershellModuleExactOrLatest -ModuleName $MainModule -RequiredVersion $global:ModuleRequiredVersion -Scope AllUsers
                                    }
                                Catch
                                    {
                                        write-host "Errors occurred .... terminating as modules are locked in memory !!"
                                        write-host "Close down the current Powershell session and re-run this script !"
                                        Exit 1
                                    }

                            # Re-installing current Auth module to try to fix current state!
                                Try
                                    {
                                        Install-PowershellModuleExactOrLatest -ModuleName $AuthModule -RequiredVersion $global:AuthModuleRequiredVersion -Scope AllUsers
                                    }
                                Catch
                                    {
                                        write-host "Errors occurred .... terminating as modules are locked in memory !!"
                                        write-host "Close down the current Powershell session and re-run this script !"
                                        Exit 1
                                    }

                            # Re-installing required sub-modules to try to fix current state!
                                ForEach ($RequiredModule in $RequiredModules)
                                    {
                                        Try
                                            {
                                                Install-PowershellModuleExactOrLatest -ModuleName $RequiredModule -RequiredVersion $global:ModuleRequiredVersion -Scope AllUsers
                                            }
                                        Catch
                                            {
                                                write-host "Errors occurred while re-installing required module $($RequiredModule) .... terminating as modules are locked in memory !!"
                                                write-host "Close down the current Powershell session and re-run this script !"
                                                Exit 1
                                            }
                                    }

                            # PostActionsPsModuleManagement
                                $Result = PostActionsPsModuleManagement -FileName $PostMitigationScriptKnownIssues -GitHubUri "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

                                If ($global:TerminateSession)
                                    {
                                        Write-host "Initial installation & post-actions requires the current session to be terminated and restarted !"
                                        write-host "Close down the current Powershell session and re-run this script !"
                                        Exit 1
                                    }

                            # Installed Versions
                                InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses

                            # Testing connectivity
                                $ConnectivityErrorsDetected = TestConnectivityPsModuleManagement -Entra_App_ApplicationID $Entra_App_ApplicationID `
                                                                                                 -Entra_App_CertificateThumbprint $Entra_App_CertificateThumbprint `
                                                                                                 -Entra_App_TenantID $Entra_App_TenantID `
                                                                                                 -Entra_TenantName $Entra_TenantName `
                                                                                                 -MainModule $MainModule `
                                                                                                 -AuthModule $AuthModule `
                                                                                                 -AuthModuleRequiredVersion $AuthModuleRequiredVersion `
                                                                                                 -AzSubscriptionId $AzSubscriptionId

                            If ($ConnectivityErrorsDetected)   # Errors detected
                                {
                                    $ConnectivityInstalledVersions = "CRITICAL"
                                    $CriticalErrorsOccured = $true

                                    SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                                            -SMTP_Host $SMTP_Host `
                                                                            -SMTP_UserId $SMTP_UserId `
                                                                            -SMTP_Password $SMTP_Password `
                                                                            -SMTP_Port $SMTP_Port `
                                                                            -SMTP_From $SMTP_From `
                                                                            -SMTP_To $SMTP_To `
                                                                            -SMTP_Subject "[$($Description)] CRITICAL: Complete re-installation of $($MainModule) failed" `
                                                                            -SMTP_Body "<font color=red>$($MainModule) issues were detected on $($Description). System might need to be rebooted, or there could be a conflict with other modules like Az</font><br><br>" `
                                                                            -Description $Description `
                                                                            -UseSSL $global:SMTP_UseSSL
                                }
                            ElseIf (!($ConnectivityErrorsDetected))
                                {
                                    $ConnectivityInstalledVersions = "REINSTALL_SUCCESS"

                                    SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                                            -SMTP_Host $SMTP_Host `
                                                                            -SMTP_UserId $SMTP_UserId `
                                                                            -SMTP_Password $SMTP_Password `
                                                                            -SMTP_Port $SMTP_Port `
                                                                            -SMTP_From $SMTP_From `
                                                                            -SMTP_To $SMTP_To `
                                                                            -SMTP_Subject "[$($Description)] SUCCESS: $($MainModule) re-installation succeeded" `
                                                                            -SMTP_Body "<font color=red>Complete $($MainModule) re-installation succeeded on $($Description)</font><br><br>" `
                                                                            -Description $Description `
                                                                            -UseSSL $global:SMTP_UseSSL
                                }
                        }
            }


    #-----------------------------------------------------------------------------------------------------------------------------------------------------------
    # Checking if Module is available online in a newer version in Powershell Gallery
    #-----------------------------------------------------------------------------------------------------------------------------------------------------------

        write-host ""
        write-host "Getting version information from Powershell Gallery ... Please Wait !"

        # Online versions in Powershell Gallery
            If ($null -eq $global:ModuleRequiredVersion)   # use latest version
                {
                    $OnlineVersions = Find-Module -Name $MainModule -Repository PSGallery
                }
            ElseIf ($global:ModuleRequiredVersion)
                {
                    $OnlineVersions = Find-Module -Name $MainModule -Repository PSGallery -RequiredVersion $global:ModuleRequiredVersion
                }

        # Newest Online version in Powershell Gallery
            $NewestOnlineVersion = [string]$OnlineVersions.Version

            write-host ""
            Write-host "Online: Newest version in Powershell Gallery of module $($MainModule): $($NewestOnlineVersion)"

        # Compare versions
            $DesiredVersionIsLocked = -not [string]::IsNullOrWhiteSpace($global:ModuleRequiredVersion)
            $InstalledVersionDiffersFromLock = $DesiredVersionIsLocked -and (-not (Test-PowershellModuleVersionMatchesLock -InstalledVersion $CurrentInstalledVersion -RequiredVersion $NewestOnlineVersion))
            $NewerVersionAvailable = (-not $DesiredVersionIsLocked) -and (([version]$NewestOnlineVersion) -gt ([version]$CurrentInstalledVersion))

            if ( $InstalledVersionDiffersFromLock -or $NewerVersionAvailable )
                {
                    Write-host ""
                    If ($DesiredVersionIsLocked)
                        {
                            Write-host "Locked version ($($NewestOnlineVersion)) of $($MainModule) is required; installed version is $($CurrentInstalledVersion)" -ForegroundColor Yellow
                        }
                    Else
                        {
                            Write-host "Newer version ($($NewestOnlineVersion)) of $($MainModule) was detected in Powershell Gallery" -ForegroundColor Yellow
                        }

                    # Default variables
                        $UpgradeNeeded = $true
                        $UpgradeSuccess = $null
                        $UpgradeRollBack = $null

                    # Stopping all services
                        PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP
                            
                    # Update / enforce module version
                        Write-host ""
                        If ($DesiredVersionIsLocked)
                            {
                                Write-host "Enforcing locked version $($NewestOnlineVersion) of $($MainModule) from Powershell Gallery ... Please Wait !" -ForegroundColor Yellow
                                Install-PowershellModuleExactOrLatest -ModuleName $MainModule -RequiredVersion $NewestOnlineVersion -Scope AllUsers
                            }
                        Else
                            {
                                Write-host "Updating to latest version $($NewestOnlineVersion) of $($MainModule) from Powershell Gallery ... Please Wait !" -ForegroundColor Yellow
                                Update-module $MainModule -RequiredVersion $NewestOnlineVersion -Force
                            }

                    # PostActionsPsModuleManagement
                        $Result = PostActionsPsModuleManagement -FileName $PostMitigationScriptKnownIssues -GitHubUri "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

                        If ($global:TerminateSession)
                            {
                                Write-host "Initial installation & post-actions requires the current session to be terminated and restarted !"
                                write-host "Close down the current Powershell session and re-run this script !"
                                Exit 1
                            }
                    
                    # Installed Versions
                        InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses

                    # Test connectivity
                        If ($global:AuthModule)
                            {
                                $ConnectivityErrorsDetected = TestConnectivityPsModuleManagement -Entra_App_ApplicationID $Entra_App_ApplicationID `
                                                                                                 -Entra_App_CertificateThumbprint $Entra_App_CertificateThumbprint `
                                                                                                 -Entra_App_TenantID $Entra_App_TenantID `
                                                                                                 -Entra_TenantName $Entra_TenantName `
                                                                                                 -MainModule $MainModule `
                                                                                                 -AuthModule $AuthModule `
                                                                                                 -AuthModuleRequiredVersion $AuthModuleRequiredVersion `
                                                                                                 -AzSubscriptionId $AzSubscriptionId

                                If (!($ConnectivityErrorsDetected))   # No Errors detected - Upgrade succeeded
                                    {
                                        $UpgradeSuccess = $true

                                        SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsSuccess `
                                                                                -SMTP_Host $SMTP_Host `
                                                                                -SMTP_UserId $SMTP_UserId `
                                                                                -SMTP_Password $SMTP_Password `
                                                                                -SMTP_Port $SMTP_Port `
                                                                                -SMTP_From $SMTP_From `
                                                                                -SMTP_To $SMTP_To `
                                                                                -SMTP_Subject "[$($Description)] SUCCESS: $($MainModule) upgraded to $($NewestOnlineVersion)" `
                                                                                -SMTP_Body "<font color=red>$($MainModule) was successfully upgraded to $($NewestOnlineVersion) on $($Description)</font><br><br>" `
                                                                                -Description $Description `
                                                                                -UseSSL $global:SMTP_UseSSL
                                    }
                                ElseIf ($ConnectivityErrorsDetected)   # Errors detected
                                    {
                                        write-host "Errors detected with new version ..... removing new version (reverting back to prior working version) !"

                                        SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                                                -SMTP_Host $SMTP_Host `
                                                                                -SMTP_UserId $SMTP_UserId `
                                                                                -SMTP_Password $SMTP_Password `
                                                                                -SMTP_Port $SMTP_Port `
                                                                                -SMTP_From $SMTP_From `
                                                                                -SMTP_To $SMTP_To `
                                                                                -SMTP_Subject "[$($Description)] ISSUE: New version $($NewestOnlineVersion) of $($MainModule) seems broken - Rollback in progress" `
                                                                                -SMTP_Body "<font color=red>$($MainModule) issues was detected on $($Description)</font><br><br>" `
                                                                                -Description $Description `
                                                                                -UseSSL $global:SMTP_UseSSL

                                        # Removing older version
                                            Write-Host "Removing older version $($NewestOnlineVersion) of $($MainModule) ... Please Wait !"

                                            Uninstall-module -Name $MainModule -RequiredVersion $NewestOnlineVersion -Force -ErrorAction SilentlyContinue
                    
                                        # Installed Versions
                                            InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses

                                        # Test connectivity
                                            $ConnectivityErrorsDetected = TestConnectivityPsModuleManagement -Entra_App_ApplicationID $Entra_App_ApplicationID `
                                                                                                             -Entra_App_CertificateThumbprint $Entra_App_CertificateThumbprint `
                                                                                                             -Entra_App_TenantID $Entra_App_TenantID `
                                                                                                             -Entra_TenantName $Entra_TenantName `
                                                                                                             -MainModule $MainModule `
                                                                                                             -AuthModule $AuthModule `
                                                                                                             -AuthModuleRequiredVersion $AuthModuleRequiredVersion `
                                                                                                             -AzSubscriptionId $AzSubscriptionId

                                            If ($ConnectivityErrorsDetected)   # Errors detected
                                                {
                                                    $UpgradeSuccess = $false
                                                    $UpgradeRollBack = $false
                                                    $CriticalErrorsOccured = $true

                                                    SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                                                            -SMTP_Host $SMTP_Host `
                                                                                            -SMTP_UserId $SMTP_UserId `
                                                                                            -SMTP_Password $SMTP_Password `
                                                                                            -SMTP_Port $SMTP_Port `
                                                                                            -SMTP_From $SMTP_From `
                                                                                            -SMTP_To $SMTP_To `
                                                                                            -SMTP_Subject "[$($Description)] ISSUE: Rollback of $($MainModule) failed" `
                                                                                            -SMTP_Body "<font color=red>$($MainModule) issues was detected on $($Description)</font><br><br>" `
                                                                                            -Description $Description `
                                                                                            -UseSSL $global:SMTP_UseSSL
                                                }
                                            Else
                                                {
                                                    $UpgradeSuccess = $false
                                                    $UpgradeRollBack = $true

                                                    SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                                                            -SMTP_Host $SMTP_Host `
                                                                                            -SMTP_UserId $SMTP_UserId `
                                                                                            -SMTP_Password $SMTP_Password `
                                                                                            -SMTP_Port $SMTP_Port `
                                                                                            -SMTP_From $SMTP_From `
                                                                                            -SMTP_To $SMTP_To `
                                                                                            -SMTP_Subject "[$($Description)] SUCCESS: Rollback to version of $($MainModule) succeeded" `
                                                                                            -SMTP_Body "<font color=black>$($MainModule) rollback to prior version succeeded on $($Description)</font><br><br>" `
                                                                                            -Description $Description `
                                                                                            -UseSSL $global:SMTP_UseSSL
                                                }
                                    }
                            }
                }
            Else
                {
                    $UpgradeNeeded = $false

                    # No new version detected ... continuing !
                    Write-host ""
                    If ($DesiredVersionIsLocked)
                        {
                            Write-host "OK - Running locked version ($($NewestOnlineVersion)) of $($MainModule)" -ForegroundColor Green
                        }
                    Else
                        {
                            Write-host "OK - Running latest version ($($NewestOnlineVersion)) of $($MainModule)" -ForegroundColor Green
                        }
                }


    #-----------------------------------------------------------------------------------------------------------------------------------------------------------
    # Removing old versions (if any)
    #-----------------------------------------------------------------------------------------------------------------------------------------------------------

        If ( (!($UpgradeNeeded)) -or ($UpgradeSuccess) )
            {
                write-host ""
                write-host "Checking if old modules of $($MainModule) incl. sub-modules should be removed .... please wait !"

                InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses -GetOldVersions

                ForEach ($Module in $Global:OldInstalledVersionsModules)
                    {
                        write-host "Removing module $($Module.Name) - version $($Module.Version) ... Please Wait !"
                        Uninstall-module -Name $Module.Name -RequiredVersion $Module.Version -Force -ErrorAction SilentlyContinue
                    }
            }
    } # For Each Module....


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#########################################################################################################
# Wrap-up | PostAction Notifications
#########################################################################################################

    If ($CriticalErrorsOccured -eq $False)
        {
            write-host ""
            write-host "-------------------------------------------------------"
            write-host ""
            write-host "All OK - No Errors Detected !"

            # Starting services
            PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Action START

            SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsSuccess `
                                                    -SMTP_Host $SMTP_Host `
                                                    -SMTP_UserId $SMTP_UserId `
                                                    -SMTP_Password $SMTP_Password `
                                                    -SMTP_Port $SMTP_Port `
                                                    -SMTP_From $SMTP_From `
                                                    -SMTP_To $SMTP_To `
                                                    -SMTP_Subject "[$($Description)] SUCCESS: Starting Automation service(s) again" `
                                                    -SMTP_Body "<font color=black>All critical Powershell modules are working as expected on $($Description)</font><br><br>" `
                                                    -Description $Description `
                                                    -UseSSL $global:SMTP_UseSSL
            write-host "Exit SUCCESS (Exit 0)"
            Stop-Transcript
            Exit 0
        }
    Else
        {
            SendMailNotificationsPsModuleManagement -SendMailAlerts $SendMailAlertsIssues `
                                                    -SMTP_Host $SMTP_Host `
                                                    -SMTP_UserId $SMTP_UserId `
                                                    -SMTP_Password $SMTP_Password `
                                                    -SMTP_Port $SMTP_Port `
                                                    -SMTP_From $SMTP_From `
                                                    -SMTP_To $SMTP_To `
                                                    -SMTP_Subject "[$($Description)] CRITICAL: Automation Windows service(s) cannot be started as one or more errors occurred" `
                                                    -SMTP_Body "<font color=black>Critical powershell module(s) detected as broken on $($Description)</font><br><br>" `
                                                    -Description $Description `
                                                    -UseSSL $global:SMTP_UseSSL
            write-host "Exit FAILURE (Exit 1)"
            Stop-Transcript
            Exit 1
        }


#---------------------------------------------------------------------------------------------------------------------------------------
