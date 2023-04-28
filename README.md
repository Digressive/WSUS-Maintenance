# WSUS Maintenance Utility

## Clean up WSUS

For full change log and more information, [visit my site.](https://gal.vin/utils/wsus-maint-utility/)

WSUS Maintenance Utility is available from:

* [GitHub](https://github.com/Digressive/WSUS-Maintenance)
* [The Microsoft PowerShell Gallery](https://www.powershellgallery.com/packages/Wsus-Maintenance)

Please consider supporting my work:

* Sign up using [Patreon](https://www.patreon.com/mikegalvin).
* Support with a one-time donation using [PayPal](https://www.paypal.me/digressive).

Please report any problems via the ‘issues’ tab on GitHub.

-Mike

## Features and Requirements

* Designed to run on a WSUS server or can be run from a remote computer.
* The computer must have the WSUS management PowerShell modules installed.
* The utility requires at least PowerShell 5.0
* Tested on Windows 11, Windows 10, Windows Server 2022, Windows Server 2019 and Windows Server 2016.

## Generating A Password File For SMTP Authentication

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell on the computer and logged in with the user that will be running the utility. When you run the command, you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

``` powershell
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

## Configuration

Here’s a list of all the command line switches and example configurations.

| Command Line Switch | Description | Example |
| ------------------- | ----------- | ------- |
| -Run | Run the maintenance routine on the local computer. | N/A |
| -Server | The WSUS server to run the maintenance routine on. | [server name] |
| -Port | The port WSUS is running on the server. If you do not configure this, the default port will be used. | [port number] |
| -WsusSsl | Use this option if your WSUS server uses SSL. If you do not configure the port using the above, then the default SSL port will be used. | N/A |
| -L | The path to output the log file to. | [path\] |
| -LogRotate | Remove logs produced by the utility older than X days | [number] |
| -NoBanner | Use this option to hide the ASCII art title in the console. | N/A |
| -Help | Display usage information. No arguments also displays help. | N/A |
| -Webhook | The txt file containing the URI for a webhook to send the log file to. | [path\]webhook.txt |
| -Subject | Specify a subject line. If you leave this blank the default subject will be used | "'[Server: Notification]'" |
| -SendTo | The e-mail address the log should be sent to. For multiple address, separate with a comma. | [example@contoso.com] |
| -From | The e-mail address the log should be sent from. | [example@contoso.com] |
| -Smtp | The DNS name or IP address of the SMTP server. | [smtp server address] |
| -SmtpPort | The Port that should be used for the SMTP server. If none is specified then the default of 25 will be used. | [port number] |
| -User | The user account to authenticate to the SMTP server. | [example@contoso.com] |
| -Pwd | The txt file containing the encrypted password for SMTP authentication. | [path\]ps-script-pwd.txt |
| -UseSsl | Configures the utility to connect to the SMTP server using SSL. | N/A |

## Example

``` txt
[path\]Wsus-Maintenance.ps1 -Run
```

This will run the maintenance jobs on the local server

## Change Log

### 2023-04-28: Version 23.04.28

* Minor improvement to update checker. If the internet is not reachable it silently errors out.

### 2023-03-21: Version 23.03.21

* Removed specific SMTP config info from config report.
* Added script update checker - shows if an update is available in the log and console.
* Added webhook option to send log file to.

### 2022-06-18: Version 22.06.18

* Fixed Get-Service check outputting to console.

### 2022-06-14: Version 22.05.28

* Added new feature: log can now be emailed to multiple addresses.
* Added checks and balances to help with configuration as I'm very aware that the initial configuration can be troublesome. Running the utility manually is a lot more friendly and step-by-step now.
* Added -Help to give usage instructions in the terminal. Running the script with no options will also trigger the -help switch.
* Cleaned user entered paths so that trailing slashes no longer break things or have otherwise unintended results.
* Added -LogRotate [days] to removed old logs created by the utility.
* Streamlined config report so non configured options are not shown.
* Added donation link to the ASCII banner.
* Cleaned up code, removed unneeded log noise.

### 2021-12-08: Version 21.12.08

* Configured logs path now is created, if it does not exist.
* Added OS version info.
* Added Utility version info.
* Added Hostname info.
* Added an option to specify the Port for SMTP communication.
* Changed a variable to prevent conflicts with future PowerShell versions.

### 2020-03-20: Version 20.03.20

* Added code contribution from ideas@habs.homelinux.net.
* Individual clean-up jobs now run separately.
* Improved reporting.
* Made slight improvements to documentation.

### 2020-03-05: Version 20.03.03 ‘Burger’

* Added SSL option for connecting to the WSUS server.
* Made the -Port switch optional. If it is not specified, the default port is used. If -WsusSsl is specified, the default port for SSL is used.
* Added config report.
* Added ASCII banner art when run in the console.
* Added option to disable the ASCII banner art.
* Refactored code.
* Fully backwards compatible.

### 2019-09-04 v1.8

* Added custom subject line for e-mail.

### 2019-04-23 v1.7

* The script will now not run the clean up process twice.
* The script will now report if the service isn't running before starting.

### 2017-10-16 v1.6

* Changed SMTP authentication to require an encrypted password file.
* Added instructions on how to generate an encrypted password file.

### 2017-10-07 v1.5

* Added necessary information to add the script to the PowerShell Gallery.

### 2017-09-25 v1.4

* Cleaned up formatting, minor changes to code for efficiency.

### 2017-08-11 v1.3

* Improved, cleaner logging. The log file is no longer produced from PowerShell's Transcript function.

### 2017-07-22 v1.2

* Improved commenting on the code for documentation purposes.
* Added authentication and SSL options for e-mail notification.

### 2017-05-22 v1.1

* Added configuration via command line switches.
