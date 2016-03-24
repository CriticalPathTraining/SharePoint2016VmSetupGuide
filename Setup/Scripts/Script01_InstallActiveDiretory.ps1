function Update-HostFile{

    Write-Host "Updating HOSTS file on local machine..."


    $hostsFilePath = "c:\Windows\System32\Drivers\etc\hosts"
    Clear-Content -Path $hostsFilePath 

    $dnsNames = "wingtipserver", `
                "wingtipserver.wingtip.com", 
                "wingtip.com", 
                "my.wingtip.com", 
                "intranet.wingtip.com", 
                "dev.wingtip.com", 
                "www.wingtip.com", 
                "search.wingtip.com", 
                "research.wingtip.com", 
                "disco.wingtip.com", 
                "bi.wingtip.com"

    foreach ($dnsName in $dnsNames){
        Add-Content -Path $hostsFilePath -Value "127.0.0.1`t$dnsName"
    }
 
    Write-Host "HOSTS file updated on local machine"
    Write-Host 
}

function Install-ActiveDirectory{

    Write-Host "Installing Active Directory on local machine..."

    Install-WindowsFeature –Name AD-Domain-Services -IncludeManagementTools    

    Write-Host "Active Directory installed on local machine"
    Write-Host 
}

function Create-ActiveDirectoryDomain{


    Write-Host "Creating new Active Directory domain wingtip.com..."

    $domainName = "wingtip.com"
    $domainNetbiosName = "WINGTIP"
    $administratorPassword = "Password1"

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


    Write-Host "Active Directory domain wingtip.com has been created."
    Write-Host 
}

cls

Update-HostFile

Install-ActiveDirectory

Create-ActiveDirectoryDomain

Write-Host "This script has completed."
Write-Host 
