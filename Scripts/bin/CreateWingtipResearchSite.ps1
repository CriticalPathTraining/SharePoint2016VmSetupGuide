Add-PSSnapin Microsoft.SharePoint.PowerShell

$webapp = Get-SPWebApplication -Identity "http://WingtipServer"

$siteUrl = "https://intranet.wingtip.com/"
$siteTitle = "Wingtip Intranet"
$siteAdmin1 = "Wingtip\TedP"
$siteAdmin2 = "Wingtip\Administrator"
$siteTemplate = "STS#0"

# create root site collection
Write-Host "Creating Wingtip Intranet site..."
$site = New-SPSite -HostHeaderWebApplication $webapp -Url $siteUrl -Name $siteTitle -OwnerAlias $siteAdmin1 -SecondaryOwnerAlias $siteAdmin2 -Template $siteTemplate
Write-Host "Wingtip Intranet site created"
Write-Host