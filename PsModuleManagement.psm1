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
                [string]$ModuleRequiredVersion
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
                $InstalledAllVersions = Get-module $MainModule -ListAvailable -ErrorAction SilentlyContinue
                If (!($InstalledAllVersions))
                    {
                        $InstalledAllVersions = @()
                    }

            # Sub modules - Getting information about latest installed version of sub-modules module
                write-host ""
                write-host "Getting info about sub modules of $($MainModule) ... Please Wait !"
                $Submodules = Get-module "$($MainModule).*" -ListAvailable -ErrorAction SilentlyContinue
                If ($SubModules)
                    {
                        $InstalledAllVersions += $SubModules
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


Function PostActionsPsModuleManagement
{
    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$FileName,
            [Parameter(mandatory)]
                [string]$GitHubUri
         )

    write-host ""
    write-host "Known Mitigations are in progress .... Please Wait !"
    write-host ""

    $TargetFile = $env:windir + "\temp\" + $PostMitigationScriptKnownIssues
    Remove-Item $TargetFile -ErrorAction SilentlyContinue

    $ScriptFromGitHub = Invoke-WebRequest "$($GitHubUri)/$($PostMitigationScriptKnownIssues)" -OutFile $TargetFile
    & $TargetFile

Return $global:TerminateSession
}


Function PowershellServiceProcessMaintenance
{
    [CmdletBinding()]
    param(
            [Parameter()]
                [array]$Services,
            [Parameter()]
                [array]$Processes,
            [Parameter(mandatory)]
              [ValidateSet("STOP","START")]
                $Action
         )

    If ($Action -eq "STOP")
        {
            Write-host ""
            Write-host "Stopping all sessions locking Powershell modules ... Please Wait !"

            ForEach ($Service in $Services)
                {
                    write-host "Stopping service $($Service)"
                    Stop-Service $Service -ErrorAction SilentlyContinue
                }

            # Get process id of the current process, as it should not be terminated !
                $CurrentProcessID = [System.Diagnostics.Process]::GetCurrentProcess() | Select-Object -ExpandProperty 'ID'

                $Processes = Get-Process -Name $Processes  -ErrorAction SilentlyContinue
                ForEach ($Process in $Processes)
                    {
                        If ($Process.id -eq $CurrentProcessID)
                            {
                                Write-host "Skipping process $($CurrentProcessID) as it is the current process"
                            }
                        Else
                            {
                                Write-host "Terminating process $($Process.ProcessName) ($($Process.Id))"
                                Stop-Process -Id $Process.Id -Force
                            }
                    }

        }
 
    ElseIf ($Action -eq "START")
        {
            Write-host ""
            Write-host "Starting all sessions locking Powershell modules ... Please Wait !"

            ForEach ($Service in $Services)
                {
                    write-host "Starting service $($Service)"
                    Start-Service $Service -ErrorAction SilentlyContinue
                }
        }
}


Function SendMailNotificationsPsModuleManagement
{
    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [boolean]$SendMailAlerts,
            [Parameter(mandatory)]
                [string]$SMTP_Host,
            [Parameter(mandatory)]
              [AllowEmptyString()]
                     [AllowNull()]
                [string]$SMTP_UserId,
            [Parameter(mandatory)]
              [AllowEmptyString()]
                     [AllowNull()]
                [string]$SMTP_Password,
            [Parameter(mandatory)]
                [string]$SMTP_Port,
            [Parameter(mandatory)]
                [string]$SMTP_From,
            [Parameter(mandatory)]
                [array]$SMTP_To,
            [Parameter(mandatory)]
                [string]$SMTP_Subject,
            [Parameter(mandatory)]
                [string]$SMTP_Body,
            [Parameter(mandatory)]
                [string]$Description,
            [Parameter()]
              [AllowEmptyString()]
                     [AllowNull()]
                [boolean]$UseSSL = $false
         )

    If ($SendMailAlerts)
        {
            $SMTP_Body += "<br>"
            $SMTP_Body += "Mail sent from $($Description) using SMTP Host: $($SMTP_Host)<br>"

            If ( ($SMTP_UserId -eq "") -or ($SMTP_UserId -eq $null) )
                {
                    $SMTP_Body += "SMTP Authentication: Anonymous"

                    If ($UseSSL)
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (anonymous)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -UseSsl
                        }
                    Else
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (anonymous)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port
                        }
                }
            Else
                {
                    $SMTP_Body += "SMTP Authentication: Userid/password"

                    $SecureCredentialsSMTP = New-Object System.Management.Automation.PSCredential($SMTP_UserId,(ConvertTo-SecureString $SMTP_Password -AsPlainText -Force))

                    If ($UseSSL)
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (secure)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -Credential $SecureCredentialsSMTP -UseSsl
                        }
                    Else
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (secure)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -Credential $SecureCredentialsSMTP
                        }
                }
        }
}


Function TestConnectivityPsModuleManagement
{
    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$Entra_App_ApplicationID,
            [Parameter()]
                [string]$Entra_App_Secret,
            [Parameter(mandatory)]
                [string]$Entra_App_TenantID,
            [Parameter(mandatory)]
                [string]$Entra_TenantName,
            [Parameter()]
                [string]$Entra_App_CertificateThumbprint,
            [Parameter(mandatory)]
                [string]$MainModule,
            [Parameter()]
              [AllowEmptyString()]
                     [AllowNull()]
                [string]$AuthModule,
            [Parameter()]
              [AllowEmptyString()]
                     [AllowNull()]
                [string]$AuthModuleRequiredVersion,
            [Parameter()]
                [string]$AzSubscriptionId
         )

    # Default
    $ErrorsDetected = $False

    write-host ""
    write-host "Testing connectivity with $($MainModule)"

    If ($AuthModule)
        {
            write-host ""
            write-host "Auth Module version: $($AuthModuleRequiredVersion)"
            import-module $AuthModule -RequiredVersion $AuthModuleRequiredVersion
        }

    #------------------------------------------------------------------------------------------------
    If ( ($MainModule -eq "Microsoft.Graph") -or ($MainModule -eq "Microsoft.Graph.Beta")  )
        {
            Try
                {

                    If ($Entra_App_Secret)
                        {
                            $Disconnect = Disconnect-MgGraph -ErrorAction SilentlyContinue

                            $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($Entra_App_ApplicationID, (ConvertTo-SecureString $Entra_App_Secret -AsPlainText -Force))

                            Connect-MgGraph -TenantId $Entra_App_TenantID -ClientSecretCredential $ClientSecretCredential -NoWelcome -ErrorAction Stop
                        }
                    ElseIf ($Entra_App_CertificateThumbprint)
                        {
                            $Disconnect = Disconnect-MgGraph -ErrorAction SilentlyContinue

                            Connect-MgGraph -CertificateThumbprint $Entra_App_CertificateThumbprint -ClientId $Entra_App_ApplicationID -TenantId $Entra_App_TenantID  -NoWelcome -ErrorAction Stop
                        }
                }
            Catch
                {
                    $ErrorsDetected = $True
                    write-host "CONNECTIVITY ERRORS DETECTED" -ForegroundColor Yellow
                    write-host ""
                    $_
                    write-host ""
                }
        }
    #------------------------------------------------------------------------------------------------
    ElseIf ($MainModule -eq "Azure")
        {
            Try
                {
                    If ($Entra_App_Secret)
                        {
                            $Disconnect = Disconnect-AzAccount -ErrorAction SilentlyContinue

                            $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($Entra_App_ApplicationID, (ConvertTo-SecureString $Entra_App_Secret -AsPlainText -Force))

                            Connect-AzAccount -ServicePrincipal -TenantId $Entra_App_TenantID -Credential $ClientSecretCredential -SkipContextPopulation -Force -ErrorAction Stop
                    
                            Set-AzContext -Subscription $AzSubscriptionId -ErrorAction Stop
                        }
                    ElseIf ($Entra_App_CertificateThumbprint)
                        {
                            $Disconnect = Disconnect-AzAccount -ErrorAction SilentlyContinue

                            Connect-AzAccount -CertificateThumbprint $Entra_App_CertificateThumbprint -TenantId $Entra_App_TenantID -Application $Entra_App_ApplicationID -SkipContextPopulation -Force -ErrorAction Stop
                            
                            Set-AzContext -Subscription $AzSubscriptionId -ErrorAction Stop
                        }
                }
            Catch
                {
                    $ErrorsDetected = $True
                    write-host "$($MainModule) CONNECTIVITY FAILED" -ForegroundColor Yellow
                    write-host ""
                    $_
                    write-host ""
                }
        }
    #------------------------------------------------------------------------------------------------
    ElseIf ($MainModule -eq "ExchangeOnlineManagement")
        {
            Try
                {
                    If ($Entra_App_Secret)
                        {
                            Write-host "No support to Entra ID App Secret"
                        }
                    ElseIf ($Entra_App_CertificateThumbprint)
                        {
                            Connect-ExchangeOnline -CertificateThumbprint $Entra_App_CertificateThumbprint -AppId $Entra_App_ApplicationID -Organization $Entra_TenantName -ShowProgress $false
                        }
                }
            Catch
                {
                    $ErrorsDetected = $True
                    write-host "$($MainModule) CONNECTIVITY FAILED" -ForegroundColor Yellow
                    write-host ""
                    $_
                    write-host ""
                }
        }
    #------------------------------------------------------------------------------------------------
    If ($ErrorsDetected)
        {
            write-host "$($MainModule) CONNECTIVITY FAILED" -ForegroundColor Yellow
            write-host ""
        }
    ElseIf (!($ErrorsDetected))
        {
            write-host "$($MainModule) CONNECTIVITY SUCCESS" -ForegroundColor Green
            write-host ""
        }

    Return $ErrorsDetected
}


