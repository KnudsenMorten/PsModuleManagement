#########################################################################################################
# Variables
#########################################################################################################

    $global:Entra_App_ApplicationID           = "<insert the app id here>"
    $global:Entra_App_Secret                  = "<insert the secret here> - optional ! - certificate is recommended"
    $global:Entra_App_TenantID                = "<insert the tenant id here>"
    $global:Entra_App_CertificateThumbprint   = "<insert the certificate thumbprint here>"
    $global:Entra_TenantName                  = "<insert the tenant name here>"
    $global:AzSubscriptionId                  = "<insert the azure subscription here>"

    $global:MaintenancePowershellServices     = @("VisualCron")
    $global:MaintenancePowershellProcesses    = @("powershell","powershell_ise","VisualCronClient")
    $global:GitHubUri                         = "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

    $global:Description                       = $env:COMPUTERNAME + " " + "(insert companyname/location here)"

    $global:SendMailAlertsIssues              = $True
    $global:SendMailAlertsSuccess             = $false

    $global:SMTP_Host                         = "<insert smtp host name here>"
    $global:SMTP_UserId                       = "<insert smtp userid here - or $null>"
    $global:SMTP_Password                     = "<insert smtp password here - or $null>"
    $global:SMTP_Port                         = 587   # smtp port
    $global:SMTP_From                         = "<insert smtp from address here>"
    $global:SMTP_To                           = @("xxx")   # insert to-addresses as array

<#
    SAMPLE

    $global:Entra_App_ApplicationID           = "e9bcb0dc-282d-4640-xxxxxxxxxxxx"
    $global:Entra_App_Secret                  = $null
    $global:Entra_App_TenantID                = "f0fa27a0-8e7c-4f63-9a77-xxxxxxxxxxxx"
    $global:Entra_App_CertificateThumbprint   = "0e6ac8bfa9be6a984495cae2c5a35xxxxxxxxx"
    $global:Entra_TenantName                  = "xxxxx.onmicrosoft.com"
    $global:AzSubscriptionId                  = "54468121-98ba-48ba-ba59-xxxxxxxx"

    $global:MaintenancePowershellServices     = @("VisualCron")
    $global:MaintenancePowershellProcesses    = @("powershell","powershell_ise","VisualCronClient")
    $global:GitHubUri                         = "https://raw.githubusercontent.com/KnudsenMorten/PsModuleManagement/main"

    $global:Description                       = $env:COMPUTERNAME + " " + "(2LINKIT)"

    $global:SendMailAlertsIssues              = $True
    $global:SendMailAlertsSuccess             = $false

    $global:SMTP_Host                         = "smtp-relay.brevo.com"
    $global:SMTP_UserId                       = "xxxxxx@smtp-brevo.com"
    $global:SMTP_Password                     = "xxxxx"
    $global:SMTP_Port                         = 587
    $global:SMTP_From                         = "svc-automation@2linkit.net"
    $global:SMTP_To                           = @("xxxxx@2linkit.net")
#>


# Downloading latest version of PowerShell Module Management (locked)
    Write-host "Powershell Module Management"
    Write-host "Created by Morten Knudsen, Microsoft MVP (@knudsenmortendk - mok@mortenknudsen.net)"
    write-host ""
    write-host "Downloading latest version of Powershell Module Management from"
    write-host "$($GitHubUri)"
    write-host ""

    $FileName = "PowershellModuleManagement_Locked.ps1"
    $MainProgram = $PSScriptRoot + "\" + $FileName
    Remove-Item $MainProgram -ErrorAction SilentlyContinue

    $ScriptFromGitHub = Invoke-WebRequest "$($GitHubUri)/$($FileName)" -OutFile $MainProgram

# Running Main program
& $MainProgram

