
#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------

    # App / Certificates
    $Global:Certificate_Name = "FVF - Automation - Test Connectivity"
    $Global:PFX_Password     = "Access4me!"

#------------------------------------------------------------------------------------------------------------
Function Create_Certificate
#------------------------------------------------------------------------------------------------------------
{
    Write-host "Creating certificate $($global:Certificate_Name) ..."
        $cert = New-SelfSignedCertificate -CertStoreLocation "cert:\LocalMachine\My" `
            -Subject "CN=$($global:Certificate_Name)" `
            -KeySpec KeyExchange `
            -NotAfter $global:Secret_EndDate `
            -NotBefore $global:Secret_StartDate `
            -FriendlyName $($global:Certificate_Name)
        $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

        $global:Thumbprint = $cert.Thumbprint

    Write-host "Exporting certificate to .CER format"
        $certFile = Get-ChildItem -Path cert:\LocalMachine\My\$($global:Thumbprint)
        MD "C:\TMP" -ErrorAction SilentlyContinue
        $global:CertFileExport = "C:\TMP\$($global:Certificate_Name).cer"
        Export-Certificate -Cert $CertFile -FilePath $global:CertFileExport

    Write-host "Exporting certificate to .PFX format"
        $mypwd = ConvertTo-SecureString -String $global:PFX_Password -Force -AsPlainText
        $certFile | Export-PfxCertificate -FilePath "C:\TMP\$($global:Certificate_Name).pfx" -Password $mypwd

}


$Global:Secret_StartDate_Full    = (Get-date)
$Global:Secret_StartDate         = (Get-date $Secret_StartDate_Full -format dd/MM/yyyy)
$Global:Secret_EndDate_Full      = (Get-date $Secret_StartDate_Full).AddYears(2)
$Global:Secret_EndDate           = (Get-date $Secret_EndDate_Full -format dd/MM/yyyy)
Create_Certificate
        
write-host "ThumbPrint -> $($global:Thumbprint)"

