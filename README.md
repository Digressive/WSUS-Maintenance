# Automated WSUS Maintenance

PowerShell script to run the maintenance routines for Windows Server Update Services

Automated WSUS Maintenance can also be downloaded from:

* [The Microsoft TechNet Gallery](https://gallery.technet.microsoft.com/WSUS-Maintenance-w-logging-d507a15a?redir=0)
* [The PowerShell Gallery](https://www.powershellgallery.com/packages/Wsus-Maintenance)
* For full instructions and documentation, [visit my blog post](https://gal.vin/2017/08/28/automate-wsus-maintenance)

-Mike

Tweet me if you have questions: [@mikegalvin_](https://twitter.com/mikegalvin_)

## Features and Requirements

* The script will run the WSUS server cleanup process, which will delete obsolete updates, as well as declining expired and superseded updates.
* The script can optionally create a log file and e-mail the log file to an address of your choice.
* The script can be run locally on a WSUS server, or on a remote sever.
* The script requires that the WSUS management tools be installed.
* The script has been tested on Windows 10 and Windows Server 2016.

### Generating A Password File

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell, on the computer that is going to run the script and logged in with the user that will be running the script. When you run the command you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

```
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

### Configuration

Here’s a list of all the command line switches and example configurations.

```
-Server
```
The WSUS server to run the maintenance routine on.
``` 
-Port
```
The port WSUS is running on.
```
-L
```
The path to output the log file to. The file name will be Wsus-Maintenance.log
```
-SendTo
```
The e-mail address the log should be sent to.
```
-From
```
The from address the log should be sent from.
```
-Smtp
```
The DNS name or IP address of the SMTP server.
```
-User
```
The user account to connect to the SMTP server.
```
-Pwd
```
The password for the user account.
```
-UseSsl
```
Connect to the SMTP server using SSL.

### Example

```
Wsus-Maintenance.ps1 -Server wsus01 -Port 8530 -L C:\scripts\logs -SendTo me@contoso.com -From wsus@contoso.com -Smtp smtp.contoso.com -User me@contoso.com -Pwd P@ssw0rd -UseSsl
```
This will run the maintenance on the WSUS server on wsus01 hosted on port 8530. A log will be output to C:\scripts\logs and e-mailed via a authenticated smtp server using ssl.
