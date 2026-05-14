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
