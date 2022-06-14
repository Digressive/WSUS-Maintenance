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

.EXTERNALMODULEDEPENDENCIES WSUS management PowerShell modules.

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    WSUS Maintenance Utility - Clean up your WSUS.

    .DESCRIPTION
    Runs the built-in maintenance/clean up routine for WSUS.
    Run with -help or no arguments for usage.
#>

## Set up command line switches.
[CmdletBinding()]
Param(
    [alias("Server")]
    $WsusServer,
    [alias("Port")]
    $WsusPort,
    [alias("L")]
    $LogPathUsr,
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
    [switch]$Run,
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
    From a terminal run: [path\]Wsus-Maintenance.ps1 -Run
    This will run the maintenance jobs on the local server

    Use -Server [server name] to specify a remote server.
    The local computer running the script must have WSUS management tools installed.

    Enable an SSL connection to the WSUS server with -WsusSsl
    Specify the port to use with -Port [port number]
    If none is specified then the default of 8530 will be used, or 8531 if SSL is used.

    To output a log: -L [path\].
    To remove logs produced by the utility older than X days: -LogRotate [number].
    Run with no ASCII banner: -NoBanner

    To use the 'email log' function:
    Specify the subject line with -Subject ""'[subject line]'"" If you leave this blank a default subject will be used
    Make sure to encapsulate it with double & single quotes as per the example for Powershell to read it correctly.

    Specify the 'to' address with -SendTo [example@contoso.com]
    For multiple address, separate with a comma.

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
    If ($LogPathUsr)
    {
        ## Clean User entered string
        $LogPath = $LogPathUsr.trimend('\')

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
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [INFO] $Evt"
            }

            Write-Host -Object "$(Get-DateFormat) [INFO] $Evt"
        }

        If ($Type -eq "Succ")
        {
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [SUCCESS] $Evt"
            }

            Write-Host -ForegroundColor Green -Object "$(Get-DateFormat) [SUCCESS] $Evt"
        }

        If ($Type -eq "Err")
        {
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$(Get-DateFormat) [ERROR] $Evt"
            }

            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "$(Get-DateFormat) [ERROR] $Evt"
        }

        If ($Type -eq "Conf")
        {
            If ($LogPathUsr)
            {
                Add-Content -Path $Log -Encoding ASCII -Value "$Evt"
            }

            Write-Host -ForegroundColor Cyan -Object "$Evt"
        }
    }

    ## If WSUS Server is null, set it to local
    If ($Null -eq $WsusServer)
    {
        $WsusServer = $env:ComputerName

        try {
            Get-Service WsusService -ErrorAction Stop
        }

        catch {
            Write-Log -Type Err -Evt "WSUS is not installed on this local machine."
            Exit
        }
    }

    ## Default port if none is configured.
    If ($Null -eq $WsusPort -And $WsusSsl -eq $False)
    {
        $WsusPort = "8530"
    }

    If ($Null -eq $WsusPort -And $WsusSsl)
    {
        $WsusPort = "8531"
    }

    If ($Null -eq $LogPathUsr -And $SmtpServer)
    {
        Write-Log -Type Err -Evt "You must specify -L [path\] to use the email log function."
        Exit
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

    If ($LogPathUsr)
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

    If ($SmtpServer)
    {
        Write-Log -Type Conf -Evt "-UseSSL switch is:.....$UseSsl."
    }
    Write-Log -Type Conf -Evt "************************************************************"
    Write-Log -Type Info -Evt "Process started"
    ##
    ## Display current config ends here.
    ##

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
                If ($LogPathUsr)
                {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort -UseSSL | Invoke-WsusServerCleanup -$CleanUpJob | Out-File -Append $Log -Encoding ASCII"
                }
                else {
                    Invoke-Expression "Get-WsusServer -Name $WsusServer -PortNumber $WsusPort -UseSSL | Invoke-WsusServerCleanup -$CleanUpJob"
                }
            }

            else {
                If ($LogPathUsr)
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

    ## This whole block is for e-mail, if it is configured.
    If ($SmtpServer)
    {
        If (Test-Path -Path $Log)
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

            ForEach ($MailAddress in $MailTo)
            {
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
                        Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort -UseSsl -Credential $SmtpCreds
                    }

                    else {
                        Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort -Credential $SmtpCreds
                    }
                }

                else {
                    Send-MailMessage -To $MailAddress -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Port $SmtpSvrPort
                }
            }
        }

        else {
            Write-Host -ForegroundColor Red -BackgroundColor Black -Object "There's no log file to email."
        }
    }
    ## End of Email block
}
## End