
$domainName = "wingtip.com"
$domainNetbiosName = "WINGTIP"
$administratorPassword = "Password1"


# Install the AD-Domain-Services role on the domain controller AD2012R2
Install-WindowsFeature –Name AD-Domain-Services -IncludeManagementTools    

# Establish a new forest
Install-ADDSForest `
    -DomainName $domainName  `
    -DomainNetbiosName $domainNetbiosName `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $administratorPassword -AsPlainText -Force) `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012R2" `
    -ForestMode "Win2012R2" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true `
    -Confirm:$false