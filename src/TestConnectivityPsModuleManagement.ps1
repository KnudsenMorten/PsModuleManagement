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
    write-host "Testing connectivity with $($MainModule) using Entra App & Secret"

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
# MIIRgwYJKoZIhvcNAQcCoIIRdDCCEXACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7u9tMa6BcYm9hL7VBmGvZNFM
# iTuggg3jMIIG5jCCBM6gAwIBAgIQd70OA6G3CPhUqwZyENkERzANBgkqhkiG9w0B
# AQsFADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEp
# MCcGA1UEAxMgR2xvYmFsU2lnbiBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjAw
# NzI4MDAwMDAwWhcNMzAwNzI4MDAwMDAwWjBZMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEvMC0GA1UEAxMmR2xvYmFsU2lnbiBHQ0MgUjQ1
# IENvZGVTaWduaW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDWQk3540/GI/RsHYGmMPdIPc/Q5Y3lICKWB0Q1XQbPDx1wYOYmVPpTI2AC
# qF8CAveOyW49qXgFvY71TxkkmXzPERabH3tr0qN7aGV3q9ixLD/TcgYyXFusUGcs
# JU1WBjb8wWJMfX2GFpWaXVS6UNCwf6JEGenWbmw+E8KfEdRfNFtRaDFjCvhb0N66
# WV8xr4loOEA+COhTZ05jtiGO792NhUFVnhy8N9yVoMRxpx8bpUluCiBZfomjWBWX
# ACVp397CalBlTlP7a6GfGB6KDl9UXr3gW8/yDATS3gihECb3svN6LsKOlsE/zqXa
# 9FkojDdloTGWC46kdncVSYRmgiXnQwp3UrGZUUL/obLdnNLcGNnBhqlAHUGXYoa8
# qP+ix2MXBv1mejaUASCJeB+Q9HupUk5qT1QGKoCvnsdQQvplCuMB9LFurA6o44EZ
# qDjIngMohqR0p0eVfnJaKnsVahzEaeawvkAZmcvSfVVOIpwQ4KFbw7MueovE3vFL
# H4woeTBFf2wTtj0s/y1KiirsKA8tytScmIpKbVo2LC/fusviQUoIdxiIrTVhlBLz
# pHLr7jaep1EnkTz3ohrM/Ifll+FRh2npIsyDwLcPRWwH4UNP1IxKzs9jsbWkEHr5
# DQwosGs0/iFoJ2/s+PomhFt1Qs2JJnlZnWurY3FikCUNCCDx/wIDAQABo4IBrjCC
# AaowDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFNqzjcAkkKNrd9MMoFndIWdkdgt4MB8GA1Ud
# IwQYMBaAFB8Av0aACvx4ObeltEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCBgzA5
# BggrBgEFBQcwAYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25p
# bmdyb290cjQ1MEYGCCsGAQUFBzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24u
# Y29tL2NhY2VydC9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgwNqA0
# oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290cjQ1
# LmNybDBWBgNVHSAETzBNMEEGCSsGAQQBoDIBMjA0MDIGCCsGAQUFBwIBFiZodHRw
# czovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAIBgZngQwBBAEwDQYJ
# KoZIhvcNAQELBQADggIBAAiIcibGr/qsXwbAqoyQ2tCywKKX/24TMhZU/T70MBGf
# j5j5m1Ld8qIW7tl4laaafGG4BLX468v0YREz9mUltxFCi9hpbsf/lbSBQ6l+rr+C
# 1k3MEaODcWoQXhkFp+dsf1b0qFzDTgmtWWu4+X6lLrj83g7CoPuwBNQTG8cnqbmq
# LTE7z0ZMnetM7LwunPGHo384aV9BQGf2U33qQe+OPfup1BE4Rt886/bNIr0TzfDh
# 5uUzoL485HjVG8wg8jBzsCIc9oTWm1wAAuEoUkv/EktA6u6wGgYGnoTm5/DbhEb7
# c9krQrbJVzTHFsCm6yG5qg73/tvK67wXy7hn6+M+T9uplIZkVckJCsDZBHFKEUta
# ZMO8eHitTEcmZQeZ1c02YKEzU7P2eyrViUA8caWr+JlZ/eObkkvdBb0LDHgGK89T
# 2L0SmlsnhoU/kb7geIBzVN+nHWcrarauTYmAJAhScFDzAf9Eri+a4OFJCOHhW9c4
# 0Z4Kip2UJ5vKo7nb4jZq42+5WGLgNng2AfrBp4l6JlOjXLvSsuuKy2MIL/4e81Yp
# 4jWb2P/ppb1tS1ksiSwvUru1KZDaQ0e8ct282b+Awdywq7RLHVg2N2Trm+GFF5op
# ov3mCNKS/6D4fOHpp9Ewjl8mUCvHouKXd4rv2E0+JuuZQGDzPGcMtghyKTVTgTTc
# MIIG9TCCBN2gAwIBAgIMeWPZY2rjO3HZBQJuMA0GCSqGSIb3DQEBCwUAMFkxCzAJ
# BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8wLQYDVQQDEyZH
# bG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMDAeFw0yMzAzMjcx
# MDIxMzRaFw0yNjAzMjMxNjE4MThaMGMxCzAJBgNVBAYTAkRLMRAwDgYDVQQHEwdL
# b2xkaW5nMRAwDgYDVQQKEwcybGlua0lUMRAwDgYDVQQDEwcybGlua0lUMR4wHAYJ
# KoZIhvcNAQkBFg9tb2tAMmxpbmtpdC5uZXQwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQDMpI1rTOoWOSET3lSFQfsl/t83DCUEdoI02fNS5xlURPeGZNhi
# xQMKrhmFrdbIaEx01eY+hH9gF2AQ1ZDa7orCVSde1LDBnbFPLqcHWW5RWyzcy8Pq
# gV1QvzlFbmvTNHLm+wn1DZJ/1qJ+A+4uNUMrg13WRTiH0YWd6pwmAiQkoGC6FFwE
# usXotrT5JJNcPGlxBccm8su3kakI5B6iEuTeKh92EJM/km0pc/8o+pg+uR+f07Pp
# WcV9sS//JYCSLaXWicfrWq6a7/7U/vp/Wtdz+d2DcwljpsoXd++vuwzF8cUs09uJ
# KtdyrN8Z1DxqFlMdlD0ZyR401qAX4GO2XdzH363TtEBKAwvV+ReW6IeqGp5FUjnU
# j0RZ7NPOSiPr5G7d23RutjCHlGzbUr+5mQV/IHGL9LM5aNHsu22ziVqImRU9nwfq
# QVb8Q4aWD9P92hb3jNcH4bIWiQYccf9hgrMGGARx+wd/vI+AU/DfEtN9KuLJ8rNk
# LfbXRSB70le5SMP8qK09VjNXK/i6qO+Hkfh4vfNnW9JOvKdgRnQjmNEIYWjasbn8
# GyvoFVq0GOexiF/9XFKwbdGpDLJYttfcVZlBoSMPOWRe8HEKZYbJW1McjVIpWPnP
# d6tW7CBY2jp4476OeoPpMiiApuc7BhUC0VWl1Ei2PovDUoh/H3euHrWqbQIDAQAB
# o4IBsTCCAa0wDgYDVR0PAQH/BAQDAgeAMIGbBggrBgEFBQcBAQSBjjCBizBKBggr
# BgEFBQcwAoY+aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3Nn
# Y2NyNDVjb2Rlc2lnbmNhMjAyMC5jcnQwPQYIKwYBBQUHMAGGMWh0dHA6Ly9vY3Nw
# Lmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25jYTIwMjAwVgYDVR0gBE8w
# TTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkGA1UdEwQCMAAwRQYDVR0f
# BD4wPDA6oDigNoY0aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9nc2djY3I0NWNv
# ZGVzaWduY2EyMDIwLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBTas43AJJCja3fTDKBZ3SFnZHYLeDAdBgNVHQ4EFgQUMcaWNqucqymu1RTg02YU
# 3zypsskwDQYJKoZIhvcNAQELBQADggIBAHt/DYGUeCFfbtuuP5/44lpR2wbvOO49
# b6TenaL8TL3VEGe/NHh9yc3LxvH6PdbjtYgyGZLEooIgfnfEo+WL4fqF5X2BH34y
# EAsHCJVjXIjs1mGc5fajx14HU52iLiQOXEfOOk3qUC1TF3NWG+9mezho5XZkSMRo
# 0Ypg7Js2Pk3U7teZReCJFI9FSYa/BT2DnRFWVTlx7T5lIz6rKvTO1qQC2G3NKVGs
# HMtBTjsF6s2gpOzt7zF3o+DsnJukQRn0R9yTzgrx9nXYiHz6ti3HuJ4U7i7ILpgS
# RNrzmpVXXSH0wYxPT6TLm9eZR8qdZn1tGSb1zoIT70arnzE90oz0x7ej1fC8IUA/
# AYhkmfa6feI7OMU5xnsUjhSiyzMVhD06+RD3t5JrbKRoCgqixGb7DGM+yZVjbmhw
# cvr3UGVld9++pbsFeCB3xk/tcMXtBPdHTESPvUjSCpFbyldxVLU6GVIdzaeHAiBy
# S0NXrJVxcyCWusK41bJ1jP9zsnnaUCRERjWF5VZsXYBhY62NSOlFiCNGNYmVt7fi
# b4V6LFGoWvIv2EsWgx/uR/ypWndjmV6uBIN/UMZAhC25iZklNLFGDZ5dCUxLuoyW
# PVCTBYpM3+bN6dmbincjG0YDeRjTVfPN5niP1+SlRwSQxtXqYoDHq+3xVzFWVBqC
# NdoiM/4DqJUBMYIDCjCCAwYCAQEwaTBZMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEvMC0GA1UEAxMmR2xvYmFsU2lnbiBHQ0MgUjQ1IENv
# ZGVTaWduaW5nIENBIDIwMjACDHlj2WNq4ztx2QUCbjAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# f61ZcgpKmSULvygOLTk1mL3iHRowDQYJKoZIhvcNAQEBBQAEggIAtG9yttZJImM9
# rziRO/hFq7IOWcWx+M3quU9s2Vkilgvxv5d2YlIfSuXK4SJydWwOMnKYcXWwlDT5
# V8iOoDNGrwW9jLNvg9AoLSyTf2YZ/ZHQdx1dta088kSPC/jXESx+LPmoQjEj310+
# wLhKYWWiE10BT2aWaylPpLC+hqZa0kIcZtVqiGifUwGqvR3tjO27iGXgh1syezRd
# VN0bKPf6SyoFneRWslrf8j++3Z8bmESSqHMBepzqDp/70NCwabNS+WIGNrfDDvUM
# zmrRnVL3ow8q4wqIzUa9JYX3TiVQj0qHo8Y1FVbcNqOOsXI6qJ3jKXMpz0Yx3IsO
# hvdEbLtz+hukBuPXEa80wuH68qPuDazMYn9s3Xzj6iho5GJUx5iGJ1f0NV1eNoPs
# rXl7m0QvVLp2RVCQBNcZJhh1Oz0JvWBCX6PmKa9BleMOnbDInR34KtR2si6waA5B
# SgnNLt85iCveVVnxZttiDvDEm9mJlPd1Tb50j1yrGiJlD3n8CCNCNCRi+7CsU0T5
# n3xLW6BlQYGdBCqdEyQFmfYs9T8VmcDNIU5m3X0YOW19mi/2/jLEXmFmjNZcmovq
# JGSZCFjWt9aq0AMKdv77TXE9Pur1ZjSwi39BOt72skqiQpds2o1S7vViYuzCEo5/
# BBQ3G7/CVWgzqyJdX+6Ui9FeCl1B+hA=
# SIG # End signature block
