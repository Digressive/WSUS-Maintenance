<#PSScriptInfo

.VERSION 22.05.28

.GUID 56dc6e4a-4f05-414c-9419-c575f17f581f

.AUTHOR Mike Galvin Contact: mike@gal.vin / twitter.com/mikegalvin_ / discord.gg/5ZsnJ5k

.COMPANYNAME Mike Galvin

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS WSUS Windows Server Update Services Maintenance Clean up

.LICENSEURI

.PROJECTURI https://gal.vin/utils/wsus-maint-utility/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    WSUS Maintenance Utility - Clean up your WSUS.

    .DESCRIPTION
    Runs the built-in maintenance/clean up routine for WSUS.
    The device that the script is being run on must have the WSUS management tools installed.

    To send a log file via e-mail using ssl and an SMTP password you must generate an encrypted password file.
    The password file is unique to both the user and machine.

    To create the password file run this command as the user and on the machine that will use the file:

    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content C:\scripts\ps-script-pwd.txt

    .PARAMETER Server
    The WSUS server to run the maintenance routine on.

    .PARAMETER Port
    The port WSUS is running on the server.
    If you do not configure this, the default port of 8530 will be used.
    If the WsusSSL switch is used the default port will be 8531.

    .PARAMETER WsusSsl
    Use this option if your WSUS server uses SSL.

    .PARAMETER NoBanner
    Use this option to hide the ASCII art title in the console.

    .PARAMETER L
    The path to output the log file to.
    The file name will be WSUS-Maint_YYYY-MM-dd_HH-mm-ss.log
    Do not add a trailing \ backslash.

    .PARAMETER LogRotate
    Instructs the utility to remove logs older than a specified number of days.

    .PARAMETER Help
    Show usage help in the command line.

    .PARAMETER Subject
    The subject line for the e-mail log.
    Encapsulate with single or double quotes.
    If no subject is specified, the default of "WSUS Maintenance Utility Log" will be used.

    .PARAMETER SendTo
    The e-mail address the log should be sent to.

    .PARAMETER From
    The e-mail address the log should be sent from.

    .PARAMETER Smtp
    The DNS name or IP address of the SMTP server.

    .PARAMETER SmtpPort
    The Port that should be used for the SMTP server.

    .PARAMETER User
    The user account to authenticate to the SMTP server.

    .PARAMETER Pwd
    The txt file containing the encrypted password for SMTP authentication.

    .PARAMETER UseSsl
    Configures the utility to connect to the SMTP server using SSL.

    .EXAMPLE
    WSUS-Maintenance.ps1 -Server wsus01 -Port 8530 -L C:\scripts\logs -Subject 'Server: WSUS Cleanup'
    -SendTo me@contoso.com -From wsus@contoso.com -Smtp smtp.outlook.com -User me@contoso.com -Pwd c:\scripts\ps-script-pwd.txt -UseSsl

    The above command will run the built-in maintenance on the WSUS server wsus01 hosted on port 8530.
    The log file will be output to C:\scripts\logs and sent via e-mail with a custom subject line.
#>

## Set up command line switches.
[CmdletBinding()]
Param(
    [alias("Server")]
    $WsusServer,
    [alias("Port")]
    $WsusPort,
    [alias("L")]
    $LogPath,
    [alias("LogRotate")]
    $LogHistory,
    [alias("Subject")]
    $MailSubject,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("SmtpPort")]
    $SmtpSvrPort,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    $SmtpPwd,
    [switch]$WsusSsl,
    [switch]$UseSsl,
    [switch]$Help,
    [switch]$NoBanner)

If ($NoBanner -eq $False)
{
    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "
    o       o  o-o  o   o  o-o      o   o             o                              
    |       | |     |   | |         |\ /|     o       |                              
    o   o   o  o-o  |   |  o-o      | O |  oo   o-o  -o- o-o o-o   oo o-o   o-o o-o  
     \ / \ /      | |   |     |     |   | | | | |  |  |  |-' |  | | | |  | |    |-'  
      o   o   o--o   o-o  o--o      o   o o-o-| o  o  o  o-o o  o o-o-o  o  o-o o-o  
                                                                                     
    o   o  o    o    o                           Mike Galvin                         
    |   |  |  o | o  |                         https://gal.vin                       
    |   | -o-   |   -o- o  o                                                         
    |   |  |  | | |  |  |  |                  Version 22.05.28                       
     o-o   o  | o |  o  o--O                 See -help for usage                     
                           |                                                         
                        o--o      Donate: https://www.paypal.me/digressive           
"
}

If ($PSBoundParameters.Values.Count -eq 0 -or $Help)
{
    Write-Host -Object "Usage:
    From a terminal run: [path\]Wsus-Maintenance.ps1 -Server [WSUS Servername Name]
    This will run the maintenance jobs on the specified WSUS server
    Enable an SSL connection to the WSUS server with -WsusSsl
    Specify the port to use with -Port [port number]
    If none is specified then the default of 8530 will be used, or 8531 if SSL is used.

    To output a log: -L [path]. To remove logs produced by the utility older than X days: -LogRotate [number].
    Run with no ASCII banner: -NoBanner

    To use the 'email log' function:
    Specify the subject line with -Subject ""'[subject line]'"" If you leave this blank a default subject will be used
    Make sure to encapsulate it with double & single quotes as per the example for Powershell to read it correctly.
    Specify the 'to' address with -SendTo [example@contoso.com]
    Specify the 'from' address with -From [example@contoso.com]
    Specify the SMTP server with -Smtp [smtp server name]
    Specify the port to use with the SMTP server with -Port [port number].
    If none is specified then the default of 25 will be used.
    Specify the user to access SMTP with -User [example@contoso.com]
    Specify the password file to use with -Pwd [path\]ps-script-pwd.txt.
    Use SSL for SMTP server connection with -UseSsl.

    To generate an encrypted password file run the following commands
    on the computer and the user that will run the script:
"
    Write-Host -Object '    $creds = Get-Credential
    $creds.Password | ConvertFrom-SecureString | Set-Content [path\]ps-script-pwd.txt'
}

else {
    ## If logging is configured, start logging.
    ## If the log file already exists, clear it.
    If ($LogPath)
    {
        ## Make sure the log directory exists.
        If ((Test-Path -Path $LogPath) -eq $False)
        {
            New-Item $LogPath -ItemType Directory -Force | Out-Null
        }

        $LogFile = ("WSUS-Maint_{0:yyyy-MM-dd_HH-mm-ss}.log" -f (Get-Date))
        $Log = "$LogPath\$LogFile"

        If (Test-Path -Path $Log)
        {
            Clear-Content -Path $Log
        }
    }

    ## Function to get date in specific format.
    Function Get-DateFormat
    {
        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    ## Function for logging.
    Function Write-Log($Type, $Evt)
    {
        If ($Type -eq "Info")
        {
            If ($LogPath)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [INFO] $Evt"
            }
            
            Write-Host -Object "$(Get-DateFormat) [INFO] $Evt"
        }

        If ($Type -eq "Succ")
        {
            If ($LogPath)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [SUCCESS] $Evt"
            }

            Write-Host -ForegroundColor Green -Object "$(Get-DateFormat) [SUCCESS] $Evt"
        }

        If ($Type -eq "Err")
        {
            If ($LogPath)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [ERROR] $Evt"
            }

            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "$(Get-DateFormat) [ERROR] $Evt"
        }

        If ($Type -eq "Conf")
        {
            If ($LogPath)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$Evt"
            }

            Write-Host -ForegroundColor Cyan -Object "$Evt"
        }
    }

    ## getting Windows Version info
    $OSVMaj = [environment]::OSVersion.Version | Select-Object -expand major
    $OSVMin = [environment]::OSVersion.Version | Select-Object -expand minor
    $OSVBui = [environment]::OSVersion.Version | Select-Object -expand build
    $OSV = "$OSVMaj" + "." + "$OSVMin" + "." + "$OSVBui"

    ##
    ## Display the current config and log if configured.
    ##

    Write-Log -Type Conf -Evt "************ Running with the following config *************."
    Write-Log -Type Conf -Evt "Utility Version:.......22.05.28"
    Write-Log -Type Conf -Evt "Hostname:..............$Env:ComputerName."
    Write-Log -Type Conf -Evt "Windows Version:.......$OSV."
    If ($WsusServer)
    {
        Write-Log -Type Conf -Evt "WSUS Server name:......$WsusServer."
    }

    If ($WsusPort)
    {
        Write-Log -Type Conf -Evt "WSUS Server port:......$WsusPort."
    }

    If ($WsusSsl)
    {
        Write-Log -Type Conf -Evt "-WsusSSL switch is:....$WsusSsl."
    }

    If ($LogPath)
    {
        Write-Log -Type Conf -Evt "Logs directory:........$LogPath."
    }

    If ($Null -ne $LogHistory)
    {
        Write-Log -Type Conf -Evt "Logs to keep:..........$LogHistory days."
    }

    If ($MailTo)
    {
        Write-Log -Type Conf -Evt "E-mail log to:.........$MailTo."
    }

    If ($MailFrom)
    {
        Write-Log -Type Conf -Evt "E-mail log from:.......$MailFrom."
    }

    If ($MailSubject)
    {
        Write-Log -Type Conf -Evt "E-mail subject:........$MailSubject."
    }

    If ($SmtpServer)
    {
        Write-Log -Type Conf -Evt "SMTP server is:........$SmtpServer."
    }

    If ($SmtpSvrPort)
    {
        Write-Log -Type Conf -Evt "SMTP Port:.............$SmtpSvrPort."
    }

    If ($SmtpUser)
    {
        Write-Log -Type Conf -Evt "SMTP user is:..........$SmtpUser."
    }

    If ($SmtpPwd)
    {
        Write-Log -Type Conf -Evt "SMTP pwd file:.........$SmtpPwd."
    }

    If ($SmtpPwd)
    {
        Write-Log -Type Conf -Evt "-UseSSL switch is:.....$UseSsl."
    }
    Write-Log -Type Conf -Evt "************************************************************"
    Write-Log -Type Info -Evt "Process started"
    ##
    ## Display current config ends here.
    ##

    ## Default port if none is configured.
    If ($Null -eq $WsusPort -And $WsusSsl -eq $False)
    {
        $WsusPort = "8530"
    }

    else {
        $WsusPort = "8531"
    }

    ## Run the Clean up process.
    Write-Log -Type Info -Evt "Connecting to WSUS server"
    Write-Log -Type Info -Evt "WSUS maintenance routine starting..."

    ## WSUS Clean up jobs
    $CleanUpJobs = "CleanupObsoleteComputers","DeclineExpiredUpdates","DeclineSupersededUpdates","CleanupObsoleteUpdates","CleanupUnneededContentFiles","CompressUpdates"

    ForEach ($CleanUpJob in $CleanUpJobs)
    {
        Write-Log -Type Info -Evt "$CleanUpJob..."
        try {
            ## If the WsusSsl switch is configured then connect to the WSUS server using SSL and if not then don't.
            If ($WsusSsl)
            {
                If ($LogPath)
                {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort -UseSSL | Invoke-WsusServerCleanup -$CleanUpJob | Out-File -Append $Log -Encoding ASCII"
                }
                else {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort -UseSSL | Invoke-WsusServerCleanup -$CleanUpJob"
                }
            }

            else {
                If ($LogPath)
                {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort | Invoke-WsusServerCleanup -$CleanUpJob | Out-File -Append $Log -Encoding ASCII"
                }
                else {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort | Invoke-WsusServerCleanup -$CleanUpJob"
                }
            }
        }
        catch {
            Write-Log -Type Err -Evt $_.Exception.Message
        }
    }

    Write-Log -Type Info -Evt "Process finished"

    If ($Null -ne $LogHistory)
    {
        ## Cleanup logs.
        Write-Log -Type Info -Evt "Deleting logs older than: $LogHistory days"
        Get-ChildItem -Path "$LogPath\WSUS-Maint_*" -File | Where-Object CreationTime -lt (Get-Date).AddDays(-$LogHistory) | Remove-Item -Recurse
    }

    ## If logging is configured then finish the log file.
    If ($LogPath)
    {
        If (Test-Path -Path $Log)
        {
            ## This whole block is for e-mail, if it is configured.
            If ($SmtpServer)
            {
                ## Default e-mail subject if none is configured.
                If ($Null -eq $MailSubject)
                {
                    $MailSubject = "WSUS Maintenance Utility Log"
                }

                ## Default Smtp Port if none is configured.
                If ($Null -eq $SmtpSvrPort)
                {
                    $SmtpSvrPort = "25"
                }

                ## Setting the contents of the log to be the e-mail body.
                $MailBody = Get-Content -Path $Log | Out-String

                ## If an smtp password is configured, get the username and password together for authentication.
                ## If an smtp password is not provided then send the e-mail without authentication and obviously no SSL.
                If ($SmtpPwd)
                {
                    $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
                    $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

                    ## If -ssl switch is used, send the email with SSL.
                    ## If it isn't then don't use SSL, but still authenticate with the credentials.
                    If ($UseSsl)
                    {
                        Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort -UseSsl -Credential $SmtpCreds
                    }

                    else {
                        Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort -Credential $SmtpCreds
                    }
                }

                else {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort
                }
            }
        }

        else {
            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "There's no log file to email."
        }
    }
}
## End