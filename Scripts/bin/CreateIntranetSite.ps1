# setup for SharePoint Solutions Lab
Add-PSSnapin "Microsoft.SharePoint.PowerShell"

$siteDomain = "intranet.wingtip.com"
$siteUrl = "http://$siteDomain"
$siteDisplayName = "Wingtip Intranet"
$siteTemplate = "STS#0"
$siteOwner = "WINGTIP\Administrator" 
$siteOwner2 = "WINGTIP\JohnD" 


cls
Write-Host 
Write-Host "This script will create the test site collection for $siteDisplayName"
Write-Host 

$site = Get-SPSite | Where-Object {$_.Url -eq $siteUrl}
if ($site -ne $null) {
  Write-Host "Deleting existing site collection at $siteUrl..." -ForegroundColor Red
  Remove-SPSite -Identity $site -Confirm:$false
}

Write-Host "Creating site collection at $siteUrl ..." -ForegroundColor Yellow
$site = New-SPSite -URL $siteUrl -Name $siteDisplayName -Template $siteTemplate -OwnerAlias $siteOwner -SecondaryOwnerAlias $siteOwner2

# add entry to HOST file to fix Visual Studio bug
$hostsFilePath = "c:\Windows\System32\Drivers\etc\hosts"
$hostFileEntry = "127.0.0.1     $siteDomain"
Add-Content -Path $hostsFilePath -Value "`r`n$hostFileEntry"
Write-Host "HOST file entry added: $hostFileEntry" -ForegroundColor Gray

Write-Host "Site collection created at $site.Url" -ForegroundColor Green
Write-Host "Launching site in Internet Explorer..." -ForegroundColor Green
Start iexplore $siteUrl