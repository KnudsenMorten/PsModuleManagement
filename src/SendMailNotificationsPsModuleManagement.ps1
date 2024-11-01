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
                [string]$Description,
            [Parameter()]
              [AllowEmptyString()]
                     [AllowNull()]
                [boolean]$UseSSL = $false
         )

    If ($SendMailAlerts)
        {
            $SMTP_Body += "<br>"
            $SMTP_Body += "Mail sent from $($Description) using SMTP Host: $($SMTP_Host)<br>"

            If ( ($SMTP_UserId -eq "") -or ($SMTP_UserId -eq $null) )
                {
                    $SMTP_Body += "SMTP Authentication: Anonymous"

                    If ($UseSSL)
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (anonymous)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -UseSsl
                        }
                    Else
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (anonymous)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port
                        }
                }
            Else
                {
                    $SMTP_Body += "SMTP Authentication: Userid/password"

                    $SecureCredentialsSMTP = New-Object System.Management.Automation.PSCredential($SMTP_UserId,(ConvertTo-SecureString $SMTP_Password -AsPlainText -Force))

                    If ($UseSSL)
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (secure)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -Credential $SecureCredentialsSMTP -UseSsl
                        }
                    Else
                        {
                            Write-host "Sending mail to $($SMTP_To) with subject '$($SMTP_Subject)' (secure)"
                            Send-MailMessage -SmtpServer $SMTP_Host -To $SMTP_To -From $SMTP_From -Subject $SMTP_Subject -Body $SMTP_Body -Encoding UTF8 -BodyAsHtml -Priority high -port $SMTP_Port -Credential $SecureCredentialsSMTP
                        }
                }
        }
}
