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
                [boolean]$UseSSL
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



# SIG # Begin signature block
# MIIaigYJKoZIhvcNAQcCoIIaezCCGncCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAY/O8oviMByJeq
# bUxQQN4FdfHXohCvOTutG0BI2jZnF6CCFsUwggNfMIICR6ADAgECAgsEAAAAAAEh
# WFMIojANBgkqhkiG9w0BAQsFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3Qg
# Q0EgLSBSMzETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2ln
# bjAeFw0wOTAzMTgxMDAwMDBaFw0yOTAzMTgxMDAwMDBaMEwxIDAeBgNVBAsTF0ds
# b2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYD
# VQQDEwpHbG9iYWxTaWduMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# zCV2kHkGeCIW9cCDtoTKKJ79BXYRxa2IcvxGAkPHsoqdBF8kyy5L4WCCRuFSqwyB
# R3Bs3WTR6/Usow+CPQwrrpfXthSGEHm7OxOAd4wI4UnSamIvH176lmjfiSeVOJ8G
# 1z7JyyZZDXPesMjpJg6DFcbvW4vSBGDKSaYo9mk79svIKJHlnYphVzesdBTcdOA6
# 7nIvLpz70Lu/9T0A4QYz6IIrrlOmOhZzjN1BDiA6wLSnoemyT5AuMmDpV8u5BJJo
# aOU4JmB1sp93/5EU764gSfytQBVI0QIxYRleuJfvrXe3ZJp6v1/BE++bYvsNbOBU
# aRapA9pu6YOTcXbGaYWCFwIDAQABo0IwQDAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0T
# AQH/BAUwAwEB/zAdBgNVHQ4EFgQUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZI
# hvcNAQELBQADggEBAEtA28BQqv7IDO/3llRFSbuWAAlBrLMThoYoBzPKa+Z0uboA
# La6kCtP18fEPir9zZ0qDx0R7eOCvbmxvAymOMzlFw47kuVdsqvwSluxTxi3kJGy5
# lGP73FNoZ1Y+g7jPNSHDyWj+ztrCU6rMkIrp8F1GjJXdelgoGi8d3s0AN0GP7URt
# 11Mol37zZwQeFdeKlrTT3kwnpEwbc3N29BeZwh96DuMtCK0KHCz/PKtVDg+Rfjbr
# w1dJvuEuLXxgi8NBURMjnc73MmuUAaiZ5ywzHzo7JdKGQM47LIZ4yWEvFLru21Vv
# 34TuBQlNvSjYcs7TYlBlHuuSl4Mx2bO1ykdYP18wggWiMIIEiqADAgECAhB4AxhC
# RXCKQc9vAbjutKlUMA0GCSqGSIb3DQEBDAUAMEwxIDAeBgNVBAsTF0dsb2JhbFNp
# Z24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQDEwpH
# bG9iYWxTaWduMB4XDTIwMDcyODAwMDAwMFoXDTI5MDMxODAwMDAwMFowUzELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKTAnBgNVBAMTIEds
# b2JhbFNpZ24gQ29kZSBTaWduaW5nIFJvb3QgUjQ1MIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAti3FMN166KuQPQNysDpLmRZhsuX/pWcdNxzlfuyTg6qE
# 9aNDm5hFirhjV12bAIgEJen4aJJLgthLyUoD86h/ao+KYSe9oUTQ/fU/IsKjT5GN
# swWyKIKRXftZiAULlwbCmPgspzMk7lA6QczwoLB7HU3SqFg4lunf+RuRu4sQLNLH
# Qx2iCXShgK975jMKDFlrjrz0q1qXe3+uVfuE8ID+hEzX4rq9xHWhb71hEHREspgH
# 4nSr/2jcbCY+6R/l4ASHrTDTDI0DfFW4FnBcJHggJetnZ4iruk40mGtwEd44ytS+
# ocCc4d8eAgHYO+FnQ4S2z/x0ty+Eo7+6CTc9Z2yxRVwZYatBg/WsHet3DUZHc86/
# vZWV7Z0riBD++ljop1fhs8+oWukHJZsSxJ6Acj2T3IyU3ztE5iaA/NLDA/CMDNJF
# 1i7nj5ie5gTuQm5nfkIWcWLnBPlgxmShtpyBIU4rxm1olIbGmXRzZzF6kfLUjHlu
# fKa7fkZvTcWFEivPmiJECKiFN84HYVcGFxIkwMQxc6GYNVdHfhA6RdktpFGQmKmg
# BzfEZRqqHGsWd/enl+w/GTCZbzH76kCy59LE+snQ8FB2dFn6jW0XMr746X4D9OeH
# dZrUSpEshQMTAitCgPKJajbPyEygzp74y42tFqfT3tWbGKfGkjrxgmPxLg4kZN8C
# AwEAAaOCAXcwggFzMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# AzAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQfAL9GgAr8eDm3pbRD2VZQu86W
# OzAfBgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDB6BggrBgEFBQcBAQRu
# MGwwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL3Jvb3Ry
# MzA7BggrBgEFBQcwAoYvaHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNl
# cnQvcm9vdC1yMy5jcnQwNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5nbG9i
# YWxzaWduLmNvbS9yb290LXIzLmNybDBHBgNVHSAEQDA+MDwGBFUdIAAwNDAyBggr
# BgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8w
# DQYJKoZIhvcNAQEMBQADggEBAKz3zBWLMHmoHQsoiBkJ1xx//oa9e1ozbg1nDnti
# 2eEYXLC9E10dI645UHY3qkT9XwEjWYZWTMytvGQTFDCkIKjgP+icctx+89gMI7qo
# Lao89uyfhzEHZfU5p1GCdeHyL5f20eFlloNk/qEdUfu1JJv10ndpvIUsXPpYd9Gu
# p7EL4tZ3u6m0NEqpbz308w2VXeb5ekWwJRcxLtv3D2jmgx+p9+XUnZiM02FLL8Mo
# fnrekw60faAKbZLEtGY/fadY7qz37MMIAas4/AocqcWXsojICQIZ9lyaGvFNbDDU
# swarAGBIDXirzxetkpNiIHd1bL3IMrTcTevZ38GQlim9wX8wgga/MIIEp6ADAgEC
# AhEAgU5CF6Epf+1azNQX+JGtdTANBgkqhkiG9w0BAQsFADBTMQswCQYDVQQGEwJC
# RTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEpMCcGA1UEAxMgR2xvYmFsU2ln
# biBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjQwNjE5MDMyNTExWhcNMzgwNzI4
# MDAwMDAwWjBZMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEvMC0GA1UEAxMmR2xvYmFsU2lnbiBHQ0MgUjQ1IENvZGVTaWduaW5nIENBIDIw
# MjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDWQk3540/GI/RsHYGm
# MPdIPc/Q5Y3lICKWB0Q1XQbPDx1wYOYmVPpTI2ACqF8CAveOyW49qXgFvY71Txkk
# mXzPERabH3tr0qN7aGV3q9ixLD/TcgYyXFusUGcsJU1WBjb8wWJMfX2GFpWaXVS6
# UNCwf6JEGenWbmw+E8KfEdRfNFtRaDFjCvhb0N66WV8xr4loOEA+COhTZ05jtiGO
# 792NhUFVnhy8N9yVoMRxpx8bpUluCiBZfomjWBWXACVp397CalBlTlP7a6GfGB6K
# Dl9UXr3gW8/yDATS3gihECb3svN6LsKOlsE/zqXa9FkojDdloTGWC46kdncVSYRm
# giXnQwp3UrGZUUL/obLdnNLcGNnBhqlAHUGXYoa8qP+ix2MXBv1mejaUASCJeB+Q
# 9HupUk5qT1QGKoCvnsdQQvplCuMB9LFurA6o44EZqDjIngMohqR0p0eVfnJaKnsV
# ahzEaeawvkAZmcvSfVVOIpwQ4KFbw7MueovE3vFLH4woeTBFf2wTtj0s/y1Kiirs
# KA8tytScmIpKbVo2LC/fusviQUoIdxiIrTVhlBLzpHLr7jaep1EnkTz3ohrM/Ifl
# l+FRh2npIsyDwLcPRWwH4UNP1IxKzs9jsbWkEHr5DQwosGs0/iFoJ2/s+PomhFt1
# Qs2JJnlZnWurY3FikCUNCCDx/wIDAQABo4IBhjCCAYIwDgYDVR0PAQH/BAQDAgGG
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0O
# BBYEFNqzjcAkkKNrd9MMoFndIWdkdgt4MB8GA1UdIwQYMBaAFB8Av0aACvx4Obel
# tEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCBgzA5BggrBgEFBQcwAYYtaHR0cDov
# L29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290cjQ1MEYGCCsGAQUF
# BzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9jb2Rlc2ln
# bmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgwNqA0oDKGMGh0dHA6Ly9jcmwuZ2xv
# YmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290cjQ1LmNybDAuBgNVHSAEJzAlMAgG
# BmeBDAEEATALBgkrBgEEAaAyATIwDAYKKwYBBAGgMgoEAjANBgkqhkiG9w0BAQsF
# AAOCAgEAMhDkvBelgxBAndOp/SfPRXKpxR9LM1lvLDIxeXGE1jZn1at0/NTyBjpu
# tdbL8UKDlr193pUsGu1q40EcpsiJMcJZbIm8KiMDWVBHSf1vUw4qKMxIVO/zIxhb
# kjZOvKNj1MP7AA+A0SDCyuWWuvCaW6qkJXoZ2/rbe1NP+baj2WPVdV8BpSjbthgp
# FGV5nNu064iYFFNQYDEMZrNR427JKSZk8BTRc3jEhI0+FKWSWat5QUbqNM+BdkY6
# kXgZc77+BvXXwYQ5oHBMCjUAXtgqMCQfMne24Xzfs0ZB4fptjePjC58vQNmlOg1k
# yb6M0RrJZSA64gD6TnohN0FwmZ1QH5l7dZB0c01FpU5Yf912apBYiWaTZKP+VPdN
# quvlIO5114iyHQw8vKGSoFbkR/xnD+p4Kd+Po8fZ4zF4pwsplGscJ10hJ4fio+/I
# QJAuXBcoJdMBRBergNp8lKhbI/wgnpuRoZD/sw3lckQsRxXz1JFyJvnyBeMBZ/dp
# td4Ftv4okIx/oSk7tyzaZCJplsT001cNKoXGu2horIvxUktkbqq4t+xNFBz6qBQ4
# zuwl6+Ri3TX5uHsHXRtDZwIIaz2/JSODgZZzB+7+WFo8N9qg21/SnDpGkpzEJhwJ
# MNol5A4dkHPUHodOaYSBkc1lfuc1+oOAatM0HUaneAimeDIlZnowggb1MIIE3aAD
# AgECAgx5Y9ljauM7cdkFAm4wDQYJKoZIhvcNAQELBQAwWTELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExLzAtBgNVBAMTJkdsb2JhbFNpZ24g
# R0NDIFI0NSBDb2RlU2lnbmluZyBDQSAyMDIwMB4XDTIzMDMyNzEwMjEzNFoXDTI2
# MDMyMzE2MTgxOFowYzELMAkGA1UEBhMCREsxEDAOBgNVBAcTB0tvbGRpbmcxEDAO
# BgNVBAoTBzJsaW5rSVQxEDAOBgNVBAMTBzJsaW5rSVQxHjAcBgkqhkiG9w0BCQEW
# D21va0AybGlua2l0Lm5ldDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AMykjWtM6hY5IRPeVIVB+yX+3zcMJQR2gjTZ81LnGVRE94Zk2GLFAwquGYWt1sho
# THTV5j6Ef2AXYBDVkNruisJVJ17UsMGdsU8upwdZblFbLNzLw+qBXVC/OUVua9M0
# cub7CfUNkn/Won4D7i41QyuDXdZFOIfRhZ3qnCYCJCSgYLoUXAS6xei2tPkkk1w8
# aXEFxybyy7eRqQjkHqIS5N4qH3YQkz+SbSlz/yj6mD65H5/Ts+lZxX2xL/8lgJIt
# pdaJx+tarprv/tT++n9a13P53YNzCWOmyhd376+7DMXxxSzT24kq13Ks3xnUPGoW
# Ux2UPRnJHjTWoBfgY7Zd3MffrdO0QEoDC9X5F5boh6oankVSOdSPRFns085KI+vk
# bt3bdG62MIeUbNtSv7mZBX8gcYv0szlo0ey7bbOJWoiZFT2fB+pBVvxDhpYP0/3a
# FveM1wfhshaJBhxx/2GCswYYBHH7B3+8j4BT8N8S030q4snys2Qt9tdFIHvSV7lI
# w/yorT1WM1cr+Lqo74eR+Hi982db0k68p2BGdCOY0QhhaNqxufwbK+gVWrQY57GI
# X/1cUrBt0akMsli219xVmUGhIw85ZF7wcQplhslbUxyNUilY+c93q1bsIFjaOnjj
# vo56g+kyKICm5zsGFQLRVaXUSLY+i8NSiH8fd64etaptAgMBAAGjggGxMIIBrTAO
# BgNVHQ8BAf8EBAMCB4AwgZsGCCsGAQUFBwEBBIGOMIGLMEoGCCsGAQUFBzAChj5o
# dHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2djY3I0NWNvZGVz
# aWduY2EyMDIwLmNydDA9BggrBgEFBQcwAYYxaHR0cDovL29jc3AuZ2xvYmFsc2ln
# bi5jb20vZ3NnY2NyNDVjb2Rlc2lnbmNhMjAyMDBWBgNVHSAETzBNMEEGCSsGAQQB
# oDIBMjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9y
# ZXBvc2l0b3J5LzAIBgZngQwBBAEwCQYDVR0TBAIwADBFBgNVHR8EPjA8MDqgOKA2
# hjRodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25jYTIw
# MjAuY3JsMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB8GA1UdIwQYMBaAFNqzjcAkkKNr
# d9MMoFndIWdkdgt4MB0GA1UdDgQWBBQxxpY2q5yrKa7VFODTZhTfPKmyyTANBgkq
# hkiG9w0BAQsFAAOCAgEAe38NgZR4IV9u264/n/jiWlHbBu847j1vpN6dovxMvdUQ
# Z780eH3JzcvG8fo91uO1iDIZksSigiB+d8Sj5Yvh+oXlfYEffjIQCwcIlWNciOzW
# YZzl9qPHXgdTnaIuJA5cR846TepQLVMXc1Yb72Z7OGjldmRIxGjRimDsmzY+TdTu
# 15lF4IkUj0VJhr8FPYOdEVZVOXHtPmUjPqsq9M7WpALYbc0pUawcy0FOOwXqzaCk
# 7O3vMXej4Oycm6RBGfRH3JPOCvH2ddiIfPq2Lce4nhTuLsgumBJE2vOalVddIfTB
# jE9PpMub15lHyp1mfW0ZJvXOghPvRqufMT3SjPTHt6PV8LwhQD8BiGSZ9rp94js4
# xTnGexSOFKLLMxWEPTr5EPe3kmtspGgKCqLEZvsMYz7JlWNuaHBy+vdQZWV3376l
# uwV4IHfGT+1wxe0E90dMRI+9SNIKkVvKV3FUtToZUh3Np4cCIHJLQ1eslXFzIJa6
# wrjVsnWM/3OyedpQJERGNYXlVmxdgGFjrY1I6UWII0Y1iZW3t+JvhXosUaha8i/Y
# SxaDH+5H/Klad2OZXq4Eg39QxkCELbmJmSU0sUYNnl0JTEu6jJY9UJMFikzf5s3p
# 2ZuKdyMbRgN5GNNV883meI/X5KVHBJDG1epigMer7fFXMVZUGoI12iIz/gOolQEx
# ggMbMIIDFwIBATBpMFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWdu
# IG52LXNhMS8wLQYDVQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcg
# Q0EgMjAyMAIMeWPZY2rjO3HZBQJuMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKsTniLe
# 6remHvhIAJn0ZOK2mqx8YWWl0lQJTWgcT/3/MA0GCSqGSIb3DQEBAQUABIICAHUm
# If+esC+AqRrE5Z4f+BZ35RTgn3mcQCKUYm5ZCHDXXMwr5SaPENksrkuSOnjqp6Rl
# XV3CgjADph+e/T67dv1MpVagSGZ75mpkpW9SzOYR+Hk38TJsxe1FXVwQRH4KXWin
# c1Sg6897ce51LtEjdrbgr22hJauNFFGdE08a6wR7x9aZvbZeg7gZLfB1HCINbwUl
# vo6iziiBym3VYxa4K/nPA9xoiX7T9m0YrMdRU1POJ8cRPXkC9JtyZrPX2+eJqwBY
# PcuoPG7akCbqjfpki4MW5AwDnVf6De0PYygkDHtYE32wlvIHfOcC/TcZL3z8f5+I
# THpQPVq9q7cwAeB8bQ8rMkCMrhlykjtQn/3xtlzS+aJy4kQYVfQo15E63uKwDiiy
# 0Qkwm3WxEsuV/Y75omNWe0UliasqrVuT/B36eASulBDfYf6iqPbg321eNNuV0DE5
# ugTht7vxXpo+JSfoe6nIDqHYJUAEb2qTCBHqX7243nbR4C06uUVFQtBYJ1IGmkXp
# envh6GSUIfpqkKTir74a3Max5ZZ+K7Sm2n2+3QLN1jxIUt3CF+kuNNSAkkfgBs+d
# JOHJUzw3qYh/jW6YWzdRRPvJrYHS51nZFnE5SaUEFKQfSWNa7FbnqsD6iY1V1JLo
# QP6hSmATPsjJ6D33Hv2cc7KLFJwTrzlYGHomL1p4
# SIG # End signature block
