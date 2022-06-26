# Vulnerable Active Directory

## About

This repository contains some scripts/notes I took while developing a vulnerable Active Directory environment.

## Details

### Setup WinRM

Initially, I wanted to set up the `WinRM` service, mostly because the clipboard wasn't working and it was annoying.

First thing you have to do is to check if the service is running, and enable it if not. An alternative to the following commands is the option 4 (*Configure Remote Management*) from `sconfig`.

```ps1
Get-Service WinRM
# Set-Service -Name WinRM -StartupType Automatic
# Start-Service WinRM
```

You also have to make sure the firewall is not blocking the port `5985` (obviously used by WinRM).

```ps1
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
```

Besides the firewall, there's also WSMan, which limits the trusted hosts who can access the WinRM server:

```ps1
# Get-Item WSMan:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Force -Value *
```

Finally, you should be able to access the server using the commands below:

```ps1
# Create a PSCredential object containing the credentials to access the server via WinRM
#   WinRM: Windows Remote Management
# the NETBIOS name seems to be required
$user = "DC1\Administrator"
$password = ConvertTo-SecureString -String "Passw0rd!" -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $password

# Test Authentication with WinRM
Test-WSMan -ComputerName 192.168.1.10 -Authentication default -Credential $credential
# It should show the System OS, something like this:
#   ProductVersion  : OS: 10.0.17763 SP: 0.0 Stack: 3.0

# Finally create a session
New-PSSession -ComputerName 192.168.1.10 -Credential $credential
Enter-PSSession -Id 1
```

After you'll install Active Directory, you'll need to change the username:

```txt
# MACHINE\Username -> DOMAIN\Username
DC1\Administrator -> VULNERABLE\Administrator

# or this one (FQDN\Username)
vulnerable.local\Administrator
```

### Set up Active Directory

```ps1
# List packages (named "features") you can install on your Windows Server
Get-WindowsFeature

# Install Active Directory
Install-Windowsfeature AD-Domain-Services
# It should return an output like this:
#   Success Restart Needed Exit Code      Feature Result
#   ------- -------------- ---------      --------------
#   True    No             Success        {Active Directory Domain Services, Remote ...

# Import modules and install set up Active Directory Forest
Import-Module ADDSDeployment

# Check if the server meets all the requirements to install an Active Directory Forest
$safe_mode_pass = ConvertTo-SecureString -String "Passw0rd!" -AsPlainText -Force
Test-ADDSForestInstallation -SafeModeAdministratorPassword $safe_mode_pass -DomainName "vulnerable.local"
Test-ADDSForestInstallation -SafeModeAdministratorPassword $safe_mode_pass -DomainName "vulnerable.local" -CreateDNSDelegation -DomainMode Win2012R2 -ForestMode Win2012R2 -DomainNetbiosName "VULNERABLE" -DatabasePath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -LogPath "C:\Windows\NTDS" -InstallDns:$true

# Install it
# -Force skips the confirmation prompt
Install-ADDSForest -SafeModeAdministratorPassword $safe_mode_pass -DomainName "vulnerable.local" -CreateDNSDelegation -DomainMode Win2012R2 -ForestMode Win2012R2 -DomainNetbiosName "VULNERABLE" -DatabasePath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -LogPath "C:\Windows\NTDS" -InstallDns:$true -Force
```

The password passed to the parameter `SafeModeAdministratorPassword` is for the *Directory Services Restore Mode* (DSRM).

### Copy files through WinRM

I also discovered that you can copy files via WinRM protocol:

```ps1
# or create it and then assign it with Get-PSSession
$session = New-PSSession -ComputerName 192.168.1.10 -Credential $credential $credential

Copy-Item -Path .\data\wordlist.txt -Destination 'C:\Users\Administrator\Documents' -ToSession $session
```
