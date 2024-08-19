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
                [string]$Description
         )

    If ($SendMailAlerts)
        {
            $SMTP_Body += "<br>"
            $SMTP_Body += "Mail sent from $($Description) using SMTP Host: $($SMTP_Host)<br>"

            If ( ($SMTP_UserId -eq "") -or ($SMTP_UserId -eq $null) )
                {
                    $SMTP_Body += "SMTP Authentication: Anonymous"

                    Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (anonymous)"
                    Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port
                }
            Else
                {
                    $SMTP_Body += "SMTP Authentication: Userid/password"

                    $SecureCredentialsSMTP = New-Object System.Management.Automation.PSCredential($SMTP_UserId,(ConvertTo-SecureString $SMTP_Password -AsPlainText -Force))

                    Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (secure)"
                    Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -Credential $SecureCredentialsSMTP
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
# MIIXHgYJKoZIhvcNAQcCoIIXDzCCFwsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBWp3f3I0QC/1+V
# 4L0cDAvERTosHy83EsC7iJZgvvqYZ6CCE1kwggVyMIIDWqADAgECAhB2U/6sdUZI
# k/Xl10pIOk74MA0GCSqGSIb3DQEBDAUAMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2ln
# bmluZyBSb290IFI0NTAeFw0yMDAzMTgwMDAwMDBaFw00NTAzMTgwMDAwMDBaMFMx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQD
# EyBHbG9iYWxTaWduIENvZGUgU2lnbmluZyBSb290IFI0NTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALYtxTDdeuirkD0DcrA6S5kWYbLl/6VnHTcc5X7s
# k4OqhPWjQ5uYRYq4Y1ddmwCIBCXp+GiSS4LYS8lKA/Oof2qPimEnvaFE0P31PyLC
# o0+RjbMFsiiCkV37WYgFC5cGwpj4LKczJO5QOkHM8KCwex1N0qhYOJbp3/kbkbuL
# ECzSx0Mdogl0oYCve+YzCgxZa4689Ktal3t/rlX7hPCA/oRM1+K6vcR1oW+9YRB0
# RLKYB+J0q/9o3GwmPukf5eAEh60w0wyNA3xVuBZwXCR4ICXrZ2eIq7pONJhrcBHe
# OMrUvqHAnOHfHgIB2DvhZ0OEts/8dLcvhKO/ugk3PWdssUVcGWGrQYP1rB3rdw1G
# R3POv72Vle2dK4gQ/vpY6KdX4bPPqFrpByWbEsSegHI9k9yMlN87ROYmgPzSwwPw
# jAzSRdYu54+YnuYE7kJuZ35CFnFi5wT5YMZkobacgSFOK8ZtaJSGxpl0c2cxepHy
# 1Ix5bnymu35Gb03FhRIrz5oiRAiohTfOB2FXBhcSJMDEMXOhmDVXR34QOkXZLaRR
# kJipoAc3xGUaqhxrFnf3p5fsPxkwmW8x++pAsufSxPrJ0PBQdnRZ+o1tFzK++Ol+
# A/Tnh3Wa1EqRLIUDEwIrQoDyiWo2z8hMoM6e+MuNrRan097VmxinxpI68YJj8S4O
# JGTfAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBQfAL9GgAr8eDm3pbRD2VZQu86WOzANBgkqhkiG9w0BAQwFAAOCAgEA
# Xiu6dJc0RF92SChAhJPuAW7pobPWgCXme+S8CZE9D/x2rdfUMCC7j2DQkdYc8pzv
# eBorlDICwSSWUlIC0PPR/PKbOW6Z4R+OQ0F9mh5byV2ahPwm5ofzdHImraQb2T07
# alKgPAkeLx57szO0Rcf3rLGvk2Ctdq64shV464Nq6//bRqsk5e4C+pAfWcAvXda3
# XaRcELdyU/hBTsz6eBolSsr+hWJDYcO0N6qB0vTWOg+9jVl+MEfeK2vnIVAzX9Rn
# m9S4Z588J5kD/4VDjnMSyiDN6GHVsWbcF9Y5bQ/bzyM3oYKJThxrP9agzaoHnT5C
# JqrXDO76R78aUn7RdYHTyYpiF21PiKAhoCY+r23ZYjAf6Zgorm6N1Y5McmaTgI0q
# 41XHYGeQQlZcIlEPs9xOOe5N3dkdeBBUO27Ql28DtR6yI3PGErKaZND8lYUkqP/f
# obDckUCu3wkzq7ndkrfxzJF0O2nrZ5cbkL/nx6BvcbtXv7ePWu16QGoWzYCELS/h
# AtQklEOzFfwMKxv9cW/8y7x1Fzpeg9LJsy8b1ZyNf1T+fn7kVqOHp53hWVKUQY9t
# W76GlZr/GnbdQNJRSnC0HzNjI3c/7CceWeQIh+00gkoPP/6gHcH1Z3NFhnj0qinp
# J4fGGdvGExTDOUmHTaCX4GUT9Z13Vunas1jHOvLAzYIwggbmMIIEzqADAgECAhB3
# vQ4DobcI+FSrBnIQ2QRHMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENv
# ZGUgU2lnbmluZyBSb290IFI0NTAeFw0yMDA3MjgwMDAwMDBaFw0zMDA3MjgwMDAw
# MDBaMFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8w
# LQYDVQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANZCTfnjT8Yj9GwdgaYw90g9
# z9DljeUgIpYHRDVdBs8PHXBg5iZU+lMjYAKoXwIC947Jbj2peAW9jvVPGSSZfM8R
# Fpsfe2vSo3toZXer2LEsP9NyBjJcW6xQZywlTVYGNvzBYkx9fYYWlZpdVLpQ0LB/
# okQZ6dZubD4Twp8R1F80W1FoMWMK+FvQ3rpZXzGviWg4QD4I6FNnTmO2IY7v3Y2F
# QVWeHLw33JWgxHGnHxulSW4KIFl+iaNYFZcAJWnf3sJqUGVOU/troZ8YHooOX1Re
# veBbz/IMBNLeCKEQJvey83ouwo6WwT/Opdr0WSiMN2WhMZYLjqR2dxVJhGaCJedD
# CndSsZlRQv+hst2c0twY2cGGqUAdQZdihryo/6LHYxcG/WZ6NpQBIIl4H5D0e6lS
# TmpPVAYqgK+ex1BC+mUK4wH0sW6sDqjjgRmoOMieAyiGpHSnR5V+cloqexVqHMRp
# 5rC+QBmZy9J9VU4inBDgoVvDsy56i8Te8UsfjCh5MEV/bBO2PSz/LUqKKuwoDy3K
# 1JyYikptWjYsL9+6y+JBSgh3GIitNWGUEvOkcuvuNp6nUSeRPPeiGsz8h+WX4VGH
# aekizIPAtw9FbAfhQ0/UjErOz2OxtaQQevkNDCiwazT+IWgnb+z4+iaEW3VCzYkm
# eVmda6tjcWKQJQ0IIPH/AgMBAAGjggGuMIIBqjAOBgNVHQ8BAf8EBAMCAYYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
# 2rONwCSQo2t30wygWd0hZ2R2C3gwHwYDVR0jBBgwFoAUHwC/RoAK/Hg5t6W0Q9lW
# ULvOljswgZMGCCsGAQUFBwEBBIGGMIGDMDkGCCsGAQUFBzABhi1odHRwOi8vb2Nz
# cC5nbG9iYWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUwRgYIKwYBBQUHMAKG
# Omh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2NvZGVzaWduaW5n
# cm9vdHI0NS5jcnQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxz
# aWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3JsMFYGA1UdIARPME0wQQYJKwYB
# BAGgMgEyMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29t
# L3JlcG9zaXRvcnkvMAgGBmeBDAEEATANBgkqhkiG9w0BAQsFAAOCAgEACIhyJsav
# +qxfBsCqjJDa0LLAopf/bhMyFlT9PvQwEZ+PmPmbUt3yohbu2XiVppp8YbgEtfjr
# y/RhETP2ZSW3EUKL2Glux/+VtIFDqX6uv4LWTcwRo4NxahBeGQWn52x/VvSoXMNO
# Ca1Za7j5fqUuuPzeDsKg+7AE1BMbxyepuaotMTvPRkyd60zsvC6c8YejfzhpX0FA
# Z/ZTfepB7449+6nUEThG3zzr9s0ivRPN8OHm5TOgvjzkeNUbzCDyMHOwIhz2hNab
# XAAC4ShSS/8SS0Dq7rAaBgaehObn8NuERvtz2StCtslXNMcWwKbrIbmqDvf+28rr
# vBfLuGfr4z5P26mUhmRVyQkKwNkEcUoRS1pkw7x4eK1MRyZlB5nVzTZgoTNTs/Z7
# KtWJQDxxpav4mVn945uSS90FvQsMeAYrz1PYvRKaWyeGhT+RvuB4gHNU36cdZytq
# tq5NiYAkCFJwUPMB/0SuL5rg4UkI4eFb1zjRngqKnZQnm8qjudviNmrjb7lYYuA2
# eDYB+sGniXomU6Ncu9Ky64rLYwgv/h7zViniNZvY/+mlvW1LWSyJLC9Su7UpkNpD
# R7xy3bzZv4DB3LCrtEsdWDY3ZOub4YUXmimi/eYI0pL/oPh84emn0TCOXyZQK8ei
# 4pd3iu/YTT4m65lAYPM8Zwy2CHIpNVOBNNwwggb1MIIE3aADAgECAgx5Y9ljauM7
# cdkFAm4wDQYJKoZIhvcNAQELBQAwWTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEds
# b2JhbFNpZ24gbnYtc2ExLzAtBgNVBAMTJkdsb2JhbFNpZ24gR0NDIFI0NSBDb2Rl
# U2lnbmluZyBDQSAyMDIwMB4XDTIzMDMyNzEwMjEzNFoXDTI2MDMyMzE2MTgxOFow
# YzELMAkGA1UEBhMCREsxEDAOBgNVBAcTB0tvbGRpbmcxEDAOBgNVBAoTBzJsaW5r
# SVQxEDAOBgNVBAMTBzJsaW5rSVQxHjAcBgkqhkiG9w0BCQEWD21va0AybGlua2l0
# Lm5ldDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMykjWtM6hY5IRPe
# VIVB+yX+3zcMJQR2gjTZ81LnGVRE94Zk2GLFAwquGYWt1shoTHTV5j6Ef2AXYBDV
# kNruisJVJ17UsMGdsU8upwdZblFbLNzLw+qBXVC/OUVua9M0cub7CfUNkn/Won4D
# 7i41QyuDXdZFOIfRhZ3qnCYCJCSgYLoUXAS6xei2tPkkk1w8aXEFxybyy7eRqQjk
# HqIS5N4qH3YQkz+SbSlz/yj6mD65H5/Ts+lZxX2xL/8lgJItpdaJx+tarprv/tT+
# +n9a13P53YNzCWOmyhd376+7DMXxxSzT24kq13Ks3xnUPGoWUx2UPRnJHjTWoBfg
# Y7Zd3MffrdO0QEoDC9X5F5boh6oankVSOdSPRFns085KI+vkbt3bdG62MIeUbNtS
# v7mZBX8gcYv0szlo0ey7bbOJWoiZFT2fB+pBVvxDhpYP0/3aFveM1wfhshaJBhxx
# /2GCswYYBHH7B3+8j4BT8N8S030q4snys2Qt9tdFIHvSV7lIw/yorT1WM1cr+Lqo
# 74eR+Hi982db0k68p2BGdCOY0QhhaNqxufwbK+gVWrQY57GIX/1cUrBt0akMsli2
# 19xVmUGhIw85ZF7wcQplhslbUxyNUilY+c93q1bsIFjaOnjjvo56g+kyKICm5zsG
# FQLRVaXUSLY+i8NSiH8fd64etaptAgMBAAGjggGxMIIBrTAOBgNVHQ8BAf8EBAMC
# B4AwgZsGCCsGAQUFBwEBBIGOMIGLMEoGCCsGAQUFBzAChj5odHRwOi8vc2VjdXJl
# Lmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2djY3I0NWNvZGVzaWduY2EyMDIwLmNy
# dDA9BggrBgEFBQcwAYYxaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vZ3NnY2Ny
# NDVjb2Rlc2lnbmNhMjAyMDBWBgNVHSAETzBNMEEGCSsGAQQBoDIBMjA0MDIGCCsG
# AQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAI
# BgZngQwBBAEwCQYDVR0TBAIwADBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25jYTIwMjAuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB8GA1UdIwQYMBaAFNqzjcAkkKNrd9MMoFndIWdkdgt4
# MB0GA1UdDgQWBBQxxpY2q5yrKa7VFODTZhTfPKmyyTANBgkqhkiG9w0BAQsFAAOC
# AgEAe38NgZR4IV9u264/n/jiWlHbBu847j1vpN6dovxMvdUQZ780eH3JzcvG8fo9
# 1uO1iDIZksSigiB+d8Sj5Yvh+oXlfYEffjIQCwcIlWNciOzWYZzl9qPHXgdTnaIu
# JA5cR846TepQLVMXc1Yb72Z7OGjldmRIxGjRimDsmzY+TdTu15lF4IkUj0VJhr8F
# PYOdEVZVOXHtPmUjPqsq9M7WpALYbc0pUawcy0FOOwXqzaCk7O3vMXej4Oycm6RB
# GfRH3JPOCvH2ddiIfPq2Lce4nhTuLsgumBJE2vOalVddIfTBjE9PpMub15lHyp1m
# fW0ZJvXOghPvRqufMT3SjPTHt6PV8LwhQD8BiGSZ9rp94js4xTnGexSOFKLLMxWE
# PTr5EPe3kmtspGgKCqLEZvsMYz7JlWNuaHBy+vdQZWV3376luwV4IHfGT+1wxe0E
# 90dMRI+9SNIKkVvKV3FUtToZUh3Np4cCIHJLQ1eslXFzIJa6wrjVsnWM/3OyedpQ
# JERGNYXlVmxdgGFjrY1I6UWII0Y1iZW3t+JvhXosUaha8i/YSxaDH+5H/Klad2OZ
# Xq4Eg39QxkCELbmJmSU0sUYNnl0JTEu6jJY9UJMFikzf5s3p2ZuKdyMbRgN5GNNV
# 883meI/X5KVHBJDG1epigMer7fFXMVZUGoI12iIz/gOolQExggMbMIIDFwIBATBp
# MFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8wLQYD
# VQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMAIMeWPZ
# Y2rjO3HZBQJuMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEJPXIlKM4iuNtVu+Y4GkkfK
# IUriZErcg3ZzgzuTzbiEMA0GCSqGSIb3DQEBAQUABIICAFnf1GxeOh6hbF8G/nKL
# b4HAHE4uZuER0adocHtXpkx764tyyegS5I9D33H7fKKkWGdrImxomDWGC09rdi7w
# fGENoT1ulePhXdzzi1U03g4TvfGDYRe4Ye3D5EfW+494BoHtRn56fc4BSYurIIJT
# pJymXpRQiHLqYGxrNX/Er4PjvMeihIuztahBHCzsL/DEYdUxzNqiH62X594tZori
# qP1CioQWw52mvK0Nc7ul1B++OStSN54DXgoT2g5vwgKbC4RkIshg8X7QEZh5IzLb
# 9uYQGyMPbSbGJUoidbrT39HLV+NiuAhV0kd4d+phNUsglIZZGFz9p/eWdcEEcEF9
# rtwTrsM3+QRB91N9VegKKeyJIM0CmI99RDfzcFdbGsKfFO/3UvWG3FgxJmvIo6Yd
# kcK7tASAFjOt8q3nAlcbTTnzrA+ECyRR1gUsH5TsFhVKB9WUAyT2ilCXJOj2oybP
# 5DFx7z8oxbGQyQFdTaUp+7NWm18fEeBZeC6UMBuepRD8Jgn99IGasikPVHP1lz4v
# HcJxWS4wpHi7/dBFgjNTDve/ydYjRdciVk88EE5+zXowdT0RmKV2royGsFaC5y4F
# y8bsPhcU6Uyl5Y/V+cXEK0XTxtE/DzF/OxRkDxUodTUkK8b4S/yYW+B5AInObOs6
# PqiZitGiEy2i9rQegZMKOI9A
# SIG # End signature block
