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
