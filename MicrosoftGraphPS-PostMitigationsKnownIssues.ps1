﻿#-----------------------------------------------------------------------------------------------------------------
# Variables
#-----------------------------------------------------------------------------------------------------------------
    $global:TerminateSession      = $false

#-----------------------------------------------------------------------------------------------------------------
# Mitigations
#-----------------------------------------------------------------------------------------------------------------

    # Forcing a maximum/specific version
    Write-host "Version: $($Global:InstalledVersionMainModule.Version)"
    write-host ""
