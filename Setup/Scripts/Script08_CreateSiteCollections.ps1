Add-PSSnapin Microsoft.SharePoint.PowerShell


$webapp = Get-SPWebApplication -Identity "http://WingtipServer"

$siteAdmin1 = "Wingtip\Administrator"
$siteAdmin2 = "Wingtip\TedP"


function Create-SiteCollection($url, $title, $template){

    $site = Get-SPSite | Where-Object {$_.Url -eq $url}
    if ($site -ne $null) {
      Write-Host "Deleting existing site collection at $url..." -ForegroundColor Red
      Remove-SPSite -Identity $site -Confirm:$false
    }
    # create site
    $site = New-SPSite `
                -HostHeaderWebApplication $webapp `
                -Url $url `
                -Name $title `
                -OwnerAlias $siteAdmin1 `
                -SecondaryOwnerAlias $siteAdmin2 `
                -Template $template

   # configure permissions for all users
   $account = $site.RootWeb.EnsureUser(" WINGTIP\domain users")
   $role = $site.RootWeb.RoleDefinitions["Contribute"] 
   $assignment = New-Object Microsoft.SharePoint.SPRoleAssignment($account)
   $assignment.RoleDefinitionBindings.Add($role)
   $site.RootWeb.RoleAssignments.Add($assignment)

   Start iexplore $url

}

Create-SiteCollection -url "https://intranet.wingtip.com" -title "Wingtip Intranet" -template "STS#0"
Create-SiteCollection -url "https://search.wingtip.com" -title "Search Center" -template "SRCHCEN#0"
Create-SiteCollection -url "https://disco.wingtip.com" -title "Discovery Center" -template "EDISC#0"
Create-SiteCollection -url "https://www.wingtip.com" -title "Wingtip Toys" -template "BLANKINTERNET#0"
Create-SiteCollection -url "https://bi.wingtip.com" -title "Wingtip BI Center" -template "BICenterSite#0"
Create-SiteCollection -url "https://dev.wingtip.com" -title "Wingtip Dev Site" -template "DEV#0"
