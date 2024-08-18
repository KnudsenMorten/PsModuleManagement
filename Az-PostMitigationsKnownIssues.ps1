#-----------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------
    $global:TerminateSession = $false

#-----------------------------------------------------------------------------------------------------------------
# Mitigations
#-----------------------------------------------------------------------------------------------------------------

    If ([version]$Global:InstalledVersionMainModule.Version -ge [version]12.0.0 )
        {
            $Setting = get-azconfig -EnableLoginByWam
            If ($Setting.Value -eq $true)
                {
                    # Fix AzV12 "Unable to acquire token for tenant 'organizations' with error 'InteractiveBrowserCredential authentication failed: A window handle must be configured"
                    Update-AzConfig -EnableLoginByWam $false
                    $global:TerminateSession = $true
                }
        }
