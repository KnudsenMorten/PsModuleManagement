$ScriptPath = "C:\SCRIPTS\PowershellModuleManagement\PowershellModuleManagement.ps1"

$taskname = "PowershellModuleManagement"
$taskdescription = "2LINKIT - Monitor and Update Critical Powershell Modules"

$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-executionpolicy bypass -file `"$($ScriptPath)`""

$trigger =  New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At 04:00

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -hours 12) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Settings $settings -User "System"
