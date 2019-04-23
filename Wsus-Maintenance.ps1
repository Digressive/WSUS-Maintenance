<#PSScriptInfo

.VERSION 1.6

.GUID 56dc6e4a-4f05-414c-9419-c575f17f581f

.AUTHOR Mike Galvin twitter.com/mikegalvin_

.COMPANYNAME

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS WSUS Windows Server Update Services Maintenance Clean up

.LICENSEURI

.PROJECTURI https://gal.vin/2017/08/28/automate-wsus-maintenance

.ICONURI

.EXTERNALMODULEDEPENDENCIES WSUS Management PowerShell module.

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    Runs the maintenance/clean up routine for WSUS.

    .DESCRIPTION
    Runs the maintenance/clean up routine for WSUS.

    This script will:
    
    Run the WSUS server clean up process, which will delete obsolete updates, as well as declining expired and superseded updates.
    It can also optionally create a log file and email the log file to an address of your choice.

    Please note: to send a log file using ssl and an SMTP password you must generate an encrypted
    password file. The password file is unique to both the user and machine.
    
    The command is as follows:

    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content c:\foo\ps-script-pwd.txt
        
    .PARAMETER Server
    The WSUS server to run the maintenance routine on.
    
    .PARAMETER Port
    The port WSUS is running on.

    .PARAMETER L
    The path to output the log file to.
    The file name will be Wsus-Maintenance.log

    .PARAMETER SendTo
    The e-mail address the log should be sent to.

    .PARAMETER From
    The from address the log should be sent from.

    .PARAMETER Smtp
    The DNS name or IP address of the SMTP server.

    .PARAMETER User
    The user account to connect to the SMTP server.

    .PARAMETER Pwd
    The password for the user account.

    .PARAMETER UseSsl
    Connect to the SMTP server using SSL.

    .EXAMPLE
    Wsus-Maintenance.ps1 -Server wsus01 -Port 8530 -L E:\scripts -SendTo me@contoso.com -From wsus@contoso.com -Smtp smtp.contoso.com -User me@contoso.com -Pwd P@ssw0rd -UseSsl
    This will run the maintenance on the WSUS server on wsus01 hosted on port 8530. A log will be output to E:\scripts and e-mailed via a authenticated smtp server using ssl.
    
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory=$True)]
    [alias("Server")]
    $WsusServer,
    [parameter(Mandatory=$True)]
    [alias("Port")]
    $WsusPort,
    [alias("L")]
    $LogPath,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    $SmtpPwd,
    [switch]$UseSsl)

## If logging is configured, start log
If ($LogPath)
{
    $LogFile = "Wsus-Maintenance.log"
    $Log = "$LogPath\$LogFile"

    ## If the log file already exists, clear it
    $LogT = Test-Path -Path $Log
    If ($LogT)
    {
        Clear-Content -Path $Log
    }

    Add-Content -Path $Log -Value "****************************************"
    Add-Content -Path $Log -Value "$(Get-Date -Format G) Log started"
    Add-Content -Path $Log -Value ""
}

## Logging
If ($LogPath)
{
    Add-Content -Path $Log -Value "$(Get-Date -Format G) WSUS maintenance routine starting..."
    Add-Content -Path $Log -Value ""
}

## Get the WSUS server configured and perform the maintainence operations
$WsusMaintCmd = Get-WsusServer | Invoke-WsusServerCleanup -CleanupObsoleteComputers -CleanupObsoleteUpdates -CleanupUnneededContentFiles -CompressUpdates -DeclineExpiredUpdates -DeclineSupersededUpdates

Get-WsusServer -Name $WsusServer -PortNumber $WsusPort

## Logging
If ($LogPath)
{
    $WsusMaintCmd | Out-File -Append $Log -Encoding ASCII
}

Else
{
    $WsusMaintCmd
}

## If log was configured stop the log
If ($LogPath)
{
    ## If log was configured stop the log
    Add-Content -Path $Log -Value ""
    Add-Content -Path $Log -Value "$(Get-Date -Format G) Log finished"
    Add-Content -Path $Log -Value "****************************************"

    ## If email was configured, set the variables for the email subject and body
    If ($SmtpServer)
    {
        $MailSubject = "WSUS Maintenance"
        $MailBody = Get-Content -Path $Log | Out-String

        ## If an email password was configured, create a variable with the username and password
        If ($SmtpPwd)
        {
            $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
            $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

            ## If ssl was configured, send the email with ssl
            If ($UseSsl)
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -UseSsl -Credential $SmtpCreds
            }

            ## If ssl wasn't configured, send the email without ssl
            Else
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Credential $SmtpCreds
            }
        }
    
        ## If an email username and password were not configured, send the email without authentication
        Else
        {
            Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer
        }
    }
}

## End
