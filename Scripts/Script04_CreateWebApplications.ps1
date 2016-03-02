Add-PSSnapin Microsoft.SharePoint.PowerShell

function Remove-DefaultWebApplication{
    #remove the existing application pool and web application at port 80
    $sp= Get-SPWebApplication | Where {$_.DisplayName -eq "SharePoint - 80"}
    if($sp -ne $null) {
        Write-Host "Removing existing Web Application (http://Wingtipserver)..."
        Remove-SPWebApplication http://Wingtipserver -Confirm:$false -DeleteIISSite:$true -RemoveContentDatabases:$true
        Write-Host "Existing Web Application (http://Wingtipserver) Removed from Farm."
    }
}

function Create-ManagedAccountForWebApps {
    #create a new Managed Account and application pool for all Web Applications
    Write-Host "Creating managed account for WINGTIP\SP_Content"
    $contentAccountName = "WINGTIP\SP_Content"
    $contentAccountPassword = "Password1"
    $contentAccountecureStringPassword = ConvertTo-SecureString -String $contentAccountPassword -AsPlainText -Force
    $credential_content = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $contentAccountName, $contentAccountecureStringPassword 
    New-SPManagedAccount -Credential $credential_content | Out-Null
    Write-Host
}

function Create-PrimaryWebApplication{

    # create variables for new web application
    $webAppName = “Wingtip Primary Web Application” 
    $port = 80
    $hostHeader = “”
    $ssl = $false
    $authProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -UseBasicAuthentication
    $url = “http://wingtipserver”
    $appPoolName = “SharePoint Default App Pool”
    $appPoolAccount = Get-SPManagedAccount -Identity "WINGTIP\SP_Content"
    $dbServer = “WingtipServer\SharePoint”
    $dbName = “SharePoint_ContentDB_PrimaryWebApplication01”

    # create new web application
    Write-Host "Creating primary web application with support for HNSC..."
    $webapp = New-SPWebApplication `
                  -Name $webAppName `
                  -Port $port `
                  -HostHeader $hostHeader `
                  -SecureSocketsLayer:$ssl `
                  -AuthenticationProvider $authProvider `
                  -URL $url `
                  -ApplicationPool $appPoolName `
                  -ApplicationPoolAccount $appPoolAccount `
                  -DatabaseServer $dbServer `
                  -DatabaseName $dbName `
                  -AllowAnonymousAccess:$true
                  

    Write-Host "Primary web application created"
    Write-Host

    # create variables for root site collection
    $siteUrl = "http://wingtipserver/"
    $siteTitle = "Wingtip Team Site"
    $siteOwner = "Wingtip\Administrator"
    $siteTemplate = "STS#0"

    # create root site collection
    Write-Host "Creating root site collection..."
    $site = New-SPSite -Url $siteUrl -Template $siteTemplate -OwnerAlias $siteOwner -Name $siteTitle
    Write-Host "Root site collection created"
    Write-Host 

}

function Create-MySiteHostWebApplication{

    # create variables for new web application
    $webAppName = “Wingtip My Site Host Web Application” 
    $port = 80
    $hostHeader = "my.wingtip.com"
    $ssl = $false
    $authProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -UseBasicAuthentication
    $url = “http://my.wingtip.com”
    $appPoolName = “SharePoint Default App Pool”
    $appPoolAccount = Get-SPManagedAccount -Identity "WINGTIP\SP_Content"
    $dbServer = “WingtipServer\SharePoint”
    $dbName = “SharePoint_ContentDB_MySiteHostWebApplication01”

    # create new web application
    Write-Host "Creating web application for My Site Host..."
    $webApplication = New-SPWebApplication `
                          -Name $webAppName `
                          -Port $port `
                          -HostHeader $hostHeader `
                          -SecureSocketsLayer:$ssl `
                          -AuthenticationProvider $authProvider `
                          -URL $url `
                          -ApplicationPool $appPoolName `
                          -DatabaseServer $dbServer `
                          -DatabaseName $dbName 

    Write-Host "My site host web application created"
    Write-Host

    # configure web application for my site host environment
    Remove-SPManagedPath -Identity "sites" -WebApplication $webApplication -Confirm:$false
    $webApplication | New-SPManagedPath -RelativeURL "my" -Explicit | Out-Null
    $webApplication | New-SPManagedPath -RelativeURL "personal"  | Out-Null

    $webApplication = Get-SPWebApplication -Identity $url
    $webApplication.SelfServiceSiteCreationEnabled = $true
    $webApplication.Update()

    # create variables for root site collection
    $siteUrl = "http://my.wingtip.com/"
    $siteTitle = "Wingtip My Site Host"
    $siteOwner = "Wingtip\Administrator"
    $siteTemplate = "SPSMSITEHOST#0"

    # create root site collection
    Write-Host "Creating root site collection..."
    $site = New-SPSite -Url $siteUrl -Template $siteTemplate -OwnerAlias $siteOwner -Name $siteTitle
    Write-Host "Root site collection created"
    Write-Host 

}

function Grant-WebApplicationPermissionsToServiceAccount{

    Write-Host "Granting SP_Services with permissions to access content DBs for each web application"

    foreach($webApplication in (Get-SPWebApplication)) {
      $webApplication.GrantAccessToProcessIdentity("WINGTIP\SP_Services")
    }

}


#remove the existing application pool and web application at port 80
Remove-DefaultWebApplication

#create managed account for all Web Applications
Create-ManagedAccountForWebApps

# create web applications 
Create-PrimaryWebApplication
Create-MySiteHostWebApplication
Grant-WebApplicationPermissionsToServiceAccount

# launch sites in Internet Explorer
#Start iexplore and launch sites at web application roots
$navOpenInBackgroundTab = 0x1000;
$ie = New-Object -com InternetExplorer.Application
$ie.Navigate2("http://wingtipserver");
$ie.Visible = $true;

Write-Host "Script complete - the Wingtip web appplications have been created"
Write-Host 

Read-Host -Prompt "Press ENTER to continue"