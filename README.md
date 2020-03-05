# WSUS Maintenance Utility

Clean up your WSUS

``` txt
o       o  o-o  o   o  o-o      o   o             o
|       | |     |   | |         |\ /|     o       |
o   o   o  o-o  |   |  o-o      | O |  oo   o-o  -o- o-o o-o   oo o-o   o-o o-o
 \ / \ /      | |   |     |     |   | | | | |  |  |  |-' |  | | | |  | |    |-'
  o   o   o--o   o-o  o--o      o   o o-o-| o  o  o  o-o o  o o-o-o  o  o-o o-o

o   o  o    o    o
|   |  |  o | o  |
|   | -o-   |   -o- o  o
|   |  |  | | |  |  |  |                 Version 20.03.03 🍔
 o-o   o  | o |  o  o--O
                       |            Mike Galvin   https://gal.vin
                    o--o
```

For full instructions and documentation, [visit my site.](https://gal.vin/2017/08/28/automate-wsus-maintenance)

Please consider supporting my work:

* Sign up [using Patreon.](https://www.patreon.com/mikegalvin)
* Support with a one-time payment [using PayPal.](https://www.paypal.me/digressive)

WSUS Maintenance Utility can also be downloaded from:

* [The Microsoft PowerShell Gallery](https://www.powershellgallery.com/packages/Wsus-Maintenance)

Tweet me if you have questions: [@mikegalvin_](https://twitter.com/mikegalvin_)

-Mike

## Features and Requirements

* It's designed to run either on a WSUS server itself, or can be run from a remote machine.
* The computer that is running the utility must have the WSUS management PowerShell modules installed.
* The utility requires at least PowerShell 5.0

This utility has been tested on Windows 10, Windows Server 2019 and Windows Server 2016.

### Generating A Password File

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell on the computer and logged in with the user that will be running the utility. When you run the command, you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

``` powershell
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

### Configuration

Here’s a list of all the command line switches and example configurations.

| Command Line Switch | Description | Example |
| ------------------- | ----------- | ------- |
| -Server | The WSUS server to run the maintenance routine on. | wsus01 |
| -Port | The port WSUS is running on the server. If you do not configure this, the default port of 8530 will be used. If the WsusSSL switch is used the default port will be 8531. | 6969 |
| -WsusSsl | Use this option if your WSUS server uses SSL. | N/A |
| -L | The path to output the log file to. The file name will be WSUS-Maint_YYYY-MM-dd_HH-mm-ss.log. Do not add a trailing \ backslash. | C:\scripts\logs |
| -NoBanner | Use this option to hide the ASCII art title in the console. | N/A |
| -Subject | The subject line for the e-mail log. Encapsulate with single or double quotes. If no subject is specified, the default of "WSUS Maintenance Utility Log" will be used. | 'Server: Notification' |
| -SendTo | The e-mail address the log should be sent to. | me@contoso.com |
| -From | The e-mail address the log should be sent from. | WsusMaint@contoso.com |
| -Smtp | The DNS name or IP address of the SMTP server. | smtp.live.com OR smtp.office365.com |
| -User | The user account to authenticate to the SMTP server. | example@contoso.com |
| -Pwd | The txt file containing the encrypted password for SMTP authentication. | C:\scripts\ps-script-pwd.txt |
| -UseSsl | Configures the utility to connect to the SMTP server using SSL. | N/A |

### Example

``` txt
WSUS-Maintenance.ps1 -Server wsus01 -L C:\scripts\logs -Subject 'Server: WSUS Maintenance' -SendTo me@contoso.com -From WSUS-Maint@contoso.com -Smtp smtp.outlook.com -User me@contoso.com -Pwd C:\foo\pwd.txt -UseSsl
```

The above command will run the maintenance on the server wsus01 using the default port. The log file will be output to C:\scripts\logs and sent via e-mail with a custom subject line.
