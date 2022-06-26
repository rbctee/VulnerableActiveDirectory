# Install Active Directory
Install-Windowsfeature AD-Domain-Services
# It should return an output like this:
#   Success Restart Needed Exit Code      Feature Result
#   ------- -------------- ---------      --------------
#   True    No             Success        {Active Directory Domain Services, Remote ...

# Import modules and install set up Active Directory Forest
Import-Module ADDSDeployment

# Install it
$safe_mode_pass = ConvertTo-SecureString -String "Passw0rd!" -AsPlainText -Force

# -Force skips the confirmation prompt
Install-ADDSForest -SafeModeAdministratorPassword $safe_mode_pass -DomainName "vulnerable.org" -CreateDnsDelegation:$false -DomainMode Win2012R2 -ForestMode Win2012R2 -DomainNetbiosName "VULNERABLE" -DatabasePath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -LogPath "C:\Windows\NTDS" -InstallDns:$true -Force
