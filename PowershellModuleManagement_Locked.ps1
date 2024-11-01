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

Function Manage-Powershell-Module
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


    $ModuleName = "PsModuleManagement"
    $Scope      = "AllUsers"
    Manage-Powershell-Module -ModuleName $ModuleName -Scope AllUsers
    Import-module PsModuleManagement -Global -force -DisableNameChecking

 
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##################################################################################################################################################################################
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$Modules = @(
                [PSCustomObject]@{
                                    MainModule                        = "ExchangeOnlineManagement"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "ExchangeOnlineManagement-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = "3.4"
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az"
                                    AuthModule                        = "Az.Accounts"
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.ConnectedMachine"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.Peering"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.DataProtection"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Az.ResourceGraph"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Az-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph"
                                    AuthModule                        = "Microsoft.Graph.Authentication"
                                    PostMitigationScriptKnownIssues   = "Microsoft.Graph-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph.Intune"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Microsoft.Graph-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "Microsoft.Graph.Beta"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "Microsoft.Graph.Beta-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "AzLogDcrIngestPS"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "AzLogDcrIngestPS-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
                [PSCustomObject]@{
                                    MainModule                        = "MicrosoftGraphPS"
                                    AuthModule                        = $null
                                    PostMitigationScriptKnownIssues   = "MicrosoftGraphPS-PostMitigationsKnownIssues.ps1"
                                    ModuleRequiredVersion             = $null
                                 }
            )

$ModulePos = 0
$ModulesTotal = $Modules.count

ForEach ($Module in $Modules)
    {

        $global:MainModule                        = $Module.MainModule
        $global:AuthModule                        = $Module.AuthModule
        $global:PostMitigationScriptKnownIssues   = $Module.PostMitigationScriptKnownIssues
        $global:ModuleRequiredVersion             = $Module.ModuleRequiredVersion
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
            InstalledModuleInfoPsModuleManagement -MainModule $MainModule -AuthModule $AuthModule -MaintenancePowershellServices $MaintenancePowershellServices -MaintenancePowershellProcesses $MaintenancePowershellProcesses -CheckInstallation -ModuleRequiredVersion $ModuleRequiredVersion

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
                    If ($InstalledAllVersionsMainModule)
                        {
                            Write-host ""
                            Write-host "Errors detected .. Re-installing version $($InstalledAllVersionsMainModule.version) of $($MainModule) ... Please Wait !"

                            # Stopping all services
                                PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP

                            # Re-installing current Main module to try to fix current state!
                                Try
                                    {
                                        install-module $MainModule -force -Scope AllUsers -AllowClobber -ErrorAction Stop
                                    }
                                Catch
                                    {
                                        write-host "Errors occured .... terminating as modules are locked in memory !!"
                                        write-host "Close down the current Powershell session and re-run this script !"
                                        Exit 1
                                    }

                            # Re-installing current Auth module to try to fix current state!
                                Try
                                    {
                                        install-module $AuthModule -force -Scope AllUsers -AllowClobber -ErrorAction Stop
                                    }
                                Catch
                                    {
                                        write-host "Errors occured .... terminating as modules are locked in memory !!"
                                        write-host "Close down the current Powershell session and re-run this script !"
                                        Exit 1
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
                            ElseIf (!($ConnectivityErrorsDetectedCurrent))
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
            If ($global:ModuleRequiredVersion -eq $null)   # use latest version
                {
                    $OnlineVersions = Find-Module -Name $MainModule -Repository PSGallery
                }
            ElseIf ($global:ModuleRequiredVersion)
                {
                    $OnlineVersions = Find-Module -Name $MainModule -Repository PSGallery -RequiredVersion $global:ModuleRequiredVersion
                }

        # Newest Online version in Powershell Gallery
            $NewestOnlineVersion = $OnlineVersions.Version

            write-host ""
            Write-host "Online: Newest version in Powershell Gallery of module $($MainModule): $($NewestOnlineVersion)"

        # Compare versions
            if ( ([version]$NewestOnlineVersion) -gt ([version]$CurrentInstalledVersion) )
                {
                    Write-host ""
                    Write-host "Newer version ($($NewestOnlineVersion)) of $($MainModule) was detected in Powershell Gallery" -ForegroundColor Yellow

                    # Default variables
                        $UpgradeNeeded = $true
                        $UpgradeSuccess = $null
                        $UpgradeRollBack = $null

                    # Stopping all services
                        PowershellServiceProcessMaintenance -Services $MaintenancePowershellServices -Processes $MaintenancePowershellProcesses -Action STOP
                            
                    # Update modules
                        Write-host ""
                        Write-host "Updating to latest version $($NewestOnlineVersion) of $($MainModule) from Powershell Gallery ... Please Wait !" -ForegroundColor Yellow

                        Update-module $MainModule -RequiredVersion $NewestOnlineVersion -Force

                    # PostActionsPsModuleManagement
                        $Result = PostActionsPsModuleManagement -FileName $PostMitigationScriptKnownIssues -GitHubUri "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

                        If ($global:TerminateSession)
                            {
                                Write-host "Initial installation & post-actions requires the current session to be terminated and restarted !"
                                write-host "Close down the current Powershell session and re-run this script !"
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
                    Write-host "OK - Running latest version ($($NewestOnlineVersion)) of $($MainModule)" -ForegroundColor Green
                }


    #-----------------------------------------------------------------------------------------------------------------------------------------------------------
    # Removing old versions (if any)
    #-----------------------------------------------------------------------------------------------------------------------------------------------------------

        If ( (!($UpgradeNeeded)) -or ($UpgradeSuccess) )
            {
                write-host ""
                write-host "Checking if old modules of $($MainModule) incl. sub-modules shoule be removed .... please wait !"

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
            Exit 1
        }


#---------------------------------------------------------------------------------------------------------------------------------------
Stop-Transcript
#---------------------------------------------------------------------------------------------------------------------------------------
