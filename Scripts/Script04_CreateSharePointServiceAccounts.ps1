cls

function Disable-LoopbackChecks{

	# Disabling internal loopback
	Write-Host "Disabling internal loopback check for accessing host header sites"
	$regPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
	$key = "DisableLoopbackCheck"
	if(test-path $regPath)	{
		$keyValue = (Get-ItemProperty $regpath).$key
		if($keyValue -ne $null){
			Set-ItemProperty -path $regPath -name $key -value "1"
		}
		else{
			$loopback = New-ItemProperty $regPath -Name $key -value "1" -PropertyType dword
		}
	}
	else{
		$loopback = New-ItemProperty $regPath -Name $key -value "1" -PropertyType dword
	}
    Write-Host
}

function New-DnsARecord($dnsName, $ipAddress) {
    Write-Host " - creating DNS A record for [$dnsName] with IP address of [$ipAddress]"
    # create WMI object to create DNS A Record
    $rec = [WmiClass]"\\wingtipserver\root\MicrosoftDNS:MicrosoftDNS_ResourceRecord"  
    $text = "$dnsName IN A $ipAddress"  
    $rec.CreateInstanceFromTextRepresentation("wingtipserver.wingtip.com", "wingtip.com", $text)  | Out-Null
} 

function Create-WingtipDnsRecords(){

    Write-Host "Creating DNS records required for sites in farm"
    New-DnsARecord -dnsName '*.wingtip.com' -ipAddress 127.0.0.1
    Write-Host
}

function Add-TrustedSiteToInternetExplorer{
    # remember current location
    $loc = Get-Location
    
    # add registrty entries for IE trusted sites
    Set-Location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-Location ZoneMap\Domains 
    New-Item *.wingtip.com | Out-Null
    Set-Location *.wingtip.com
    New-ItemProperty . -Name http -Value 1 -Type DWORD  | Out-Null
    New-ItemProperty . -Name https -Value 1 -Type DWORD  | Out-Null

    # return to original location
    Set-Location $loc
}

function Create-SharePointServiceAccounts{

    Write-Host "Creating Wingtip service accounts in Active Directory"

    # import module with ActiveDirectory cmdlets
    Write-Host " - loading PowerShell module with Active Directory cmdlets"
    Import-Module ActiveDirectory
   
    $WingtipDomain = "DC=wingtip,DC=com"
    $ouWingtipServiceAccountsName = "Wingtip Service Accounts"
    $ouWingtipServiceAccountsPath = "OU={0},{1}" -f $ouWingtipServiceAccountsName, $WingtipDomain
    $ouWingtipServiceAccounts = Get-ADOrganizationalUnit -Filter { name -eq $ouWingtipServiceAccountsName}

    if($ouWingtipServiceAccounts -ne $null){
        Write-Host ("The Organization Unit {0} has already been created" -f $ouWingtipServiceAccountsName)
    }

    Write-Host (" - creating {0} Organization Unit" -f $ouWingtipServiceAccountsName)
    New-ADOrganizationalUnit -Name $ouWingtipServiceAccountsName -Path $WingtipDomain -ProtectedFromAccidentalDeletion $false 

    $UserPassword = ConvertTo-SecureString -AsPlainText "Password1" -Force

    # create farm service account 
    $UserName = "SP_Farm"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true

    # temporarily add SP_Farm account to local Administrators group for farm configuration 
    # NOTE: SP_Farm should be removed from Administrators group after farm configuration is complete
    $user_farm = Get-ADUser -Filter "samAccountName -eq 'SP_Farm'"
    Add-ADGroupMember -Identity "Administrators" -Members $user_farm


    # create service app service account 
    $UserName = "SP_Services"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    # add SP_Services to Performance Log Users group so it can write to ULS logs
    $user_services = Get-ADUser -Filter "samAccountName -eq 'SP_Services'"
    Add-ADGroupMember -Identity "Performance Log Users" -Members $user_services


    # create web app service account 
    $UserName = "SP_Content"
    Write-Host (" - adding User: {0}" -f $UserName)
    # add account to 'Performance Log Users' group in AD in order for ULS logging to work correctly
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    # add SP_Content to Performance Log Users group so it can write to ULS logs
    $user_content = Get-ADUser -Filter "samAccountName -eq 'SP_Content'"
    Add-ADGroupMember -Identity "Performance Log Users" -Members $user_content


    # create user profile synchronization account 
    $UserName = "SP_UPS"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    # add sp_ups account to local Administrators and Domain Admins group
    $user_ups = Get-ADUser -Filter "samAccountName -eq 'SP_UPS'"
    Add-ADGroupMember -Identity "Administrators" -Members $user_ups
    Add-ADGroupMember -Identity "Domain Admins" -Members $user_ups


    # create search crawler account 
    $UserName = "SP_Crawler"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    # add sp_crawler account to local Administrators group
    $user_crawler = Get-ADUser -Filter "samAccountName -eq 'SP_Crawler'"
    Add-ADGroupMember -Identity "Administrators" -Members $user_crawler


    # create workflow manager service account 
    $UserName = "SP_Workflow"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    # add sp_workflow account to local Administrators group
    $user_workflow = Get-ADUser -Filter "samAccountName -eq 'SP_Workflow'"
    Add-ADGroupMember -Identity "Administrators" -Members $user_workflow


    Write-Host 
}

# disable loopback checks to enable local browsing to sites
Disable-LoopbackChecks

# add DNS A records required to build farm
Create-WingtipDnsRecords

# configure [*.wingtip.com] as trusted site in Internet Explorer
Add-TrustedSiteToInternetExplorer

# create active directory accounts for SharePoint service accounts
Create-SharePointServiceAccounts

Write-Host 
Read-Host -Prompt "Press ENTER to continue"