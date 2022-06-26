Write-Host "Configure PowerShell"
Set-ExecutionPolicy RemoteSigned -Force
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Install Chocolatey"
$env:chocolateyVersion = '0.10.15'
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

Write-Host "Install System Drivers and Utilities"
choco install sdelete -y
#choco install sysinternals -y
#choco install virtio-drivers -y

Write-Host "Install WinRM"
netsh advfirewall firewall add rule name="WinRM-Install" dir=in localport=5985 protocol=TCP action=block
Get-NetConnectionProfile | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private }
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
net stop winrm
netsh advfirewall firewall delete rule name="WinRM-Install"

Write-Host "Configure WinRM"
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
net start winrm

Write-Host "Install OpenSSH"
netsh advfirewall firewall add rule name="OpenSSH-Install" dir=in localport=22 protocol=TCP action=block
choco install openssh -y --version 8.0.0.1 -params '"/SSHServerFeature"' # /PathSpecsToProbeForShellEXEString:$env:windir\system32\windowspowershell\v1.0\powershell.exe"'
net stop sshd
netsh advfirewall firewall delete rule name="OpenSSH-Install"

Write-Host "Disable password expiry for user vagrant"
wmic useraccount where "name='vagrant'" set PasswordExpires=FALSE

Write-Host "Disable Windows Defender"
Set-MpPreference -DisableRealtimeMonitoring $True -ExclusionPath "C:\"

Write-Host "Disable Storage Sense"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v AllowStorageSenseGlobal /d 0 /t REG_DWORD /f

Write-Host "Disable Windows Updates"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /d 1 /t REG_DWORD /f /reg:64

Write-Host "Disable Windows Store Updates"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /d 2 /t REG_DWORD /f /reg:64

Write-Host "Disable Maintenance"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f

Write-Host "Disable UAC"
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

Write-Host "Disable Network location wizard"
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f

Write-Host "Enable Remote Desktop"
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh advfirewall firewall add rule name="Remote Desktop" dir=in localport=3389 protocol=TCP action=allow

Write-Host "Installing VirtualBox Guest Additions"
choco install virtualbox-guest-additions-guest.install -y
#guest_additions_version = new_resource.guest_additions_options['version']
#$iso_file_source_url = "http://download.virtualbox.org/virtualbox/6.0.14/VBoxGuestAdditions_6.0.14.iso"
#Invoke-WebRequest -Uri $iso_file_source_url -OutFile "$env:windir\\temp\\vbox.iso"
#$mountResult = Mount-DiskImage "$env:windir\\temp\\vbox.iso" -PassThru -NoDriveLetter
#mountvol I: ($mountResult | Get-Volume).UniqueId
#Start-Process "I:/cert/VBoxCertUtil.exe" "add-trusted-publisher I:/cert/vbox-sha1.cer" -Wait
#Start-Process "I:/cert/VBoxCertUtil.exe" "add-trusted-publisher I:/cert/vbox-sha256.cer" -Wait
#Start-Process "I:/cert/VBoxCertUtil.exe" "add-trusted-publisher I:/cert/vbox-sha256-r3.cer" -Wait
#Start-Process "I:/VBoxWindowsAdditions.exe" "/S" -Wait
#Dismount-DiskImage "$env:windir\\temp\\vbox.iso"

Write-Host "Cleaning up system"
@(
    "$env:localappdata\temp\*",
    "$env:windir\temp\*",
    "$env:windir\logs",
    "$env:windir\panther",
    "$env:windir\winsxs\manifestcache",
    "$env:programdata\Microsoft\Windows Defender\Scans\*"
) | % {
  Write-Host "Removing $_"
  try {
    Takeown /d Y /R /f $_
    Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
    Remove-Item $_ -Recurse -Force | Out-Null
  } catch {
      $global:error.RemoveAt(0)
  }
}

Write-Host "Optimizing volume"
Optimize-Volume -DriveLetter C

Write-Host "Zeroing volume"
sdelete /accepteula -nobanner -p 3 -z C:

Write-Host "Configure OpenSSH"
$sshd_config = "$($env:ProgramData)\ssh\sshd_config"
(Get-Content $sshd_config).Replace("Match Group administrators", "# Match Group administrators") | Set-Content $sshd_config
(Get-Content $sshd_config).Replace("AuthorizedKeysFile", "# AuthorizedKeysFile") | Set-Content $sshd_config
mkdir -Force C:/Users/vagrant/.ssh
cp A:/vagrant.pub C:/Users/vagrant/.ssh/authorized_keys
sc.exe config sshd start= auto
net start sshd
