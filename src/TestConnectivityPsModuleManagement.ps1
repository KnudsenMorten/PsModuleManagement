Function TestConnectivityPsModuleManagement
{
    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$Entra_App_ApplicationID,
            [Parameter(mandatory)]
                [string]$Entra_App_Secret,
            [Parameter(mandatory)]
                [string]$Entra_App_TenantID,
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

                    $Disconnect = Disconnect-MgGraph -ErrorAction SilentlyContinue

                    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($Entra_App_ApplicationID, (ConvertTo-SecureString $Entra_App_Secret -AsPlainText -Force))

                    Connect-MgGraph -TenantId $Entra_App_TenantID -ClientSecretCredential $ClientSecretCredential -NoWelcome -ErrorAction Stop
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
                    $Disconnect = Disconnect-AzAccount -ErrorAction SilentlyContinue

                    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($Entra_App_ApplicationID, (ConvertTo-SecureString $Entra_App_Secret -AsPlainText -Force))

                    Connect-AzAccount -ServicePrincipal -TenantId $Entra_App_TenantID -Credential $ClientSecretCredential -SkipContextPopulation -Force -ErrorAction Stop
                    
                    Set-AzContext -Subscription $AzSubscriptionId -ErrorAction Stop
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
                    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($Entra_App_ApplicationID, (ConvertTo-SecureString $Entra_App_Secret -AsPlainText -Force))

                    Connect-ExchangeOnline -Credential $ClientSecretCredential -ShowProgress $false
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
