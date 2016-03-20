
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

# disable loopback checks to enable local browsing to sites
Disable-LoopbackChecks

# add DNS A records required to build farm
Create-WingtipDnsRecords

# configure [*.wingtip.com] as trusted site in Internet Explorer
Add-TrustedSiteToInternetExplorer

Write-Host "wingtip.com Domain now prepared"
Write-Host