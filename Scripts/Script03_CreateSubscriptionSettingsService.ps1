# load in SharePoint snap-in
$snapin = Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue -PassThru
if ($snapin -eq $null) {
    Write-Error "Unable to load the Microsoft.SharePoint.PowerShell Snapin! Have you installed SharePoint?"
    return
}

# assign root domain name to configure URL used to access app webs
Set-SPAppDomain "SharePointApps.wingtip.com" –confirm:$false 

$subscriptionSettingsService = Get-SPServiceInstance | where {$_.TypeName -like "Microsoft SharePoint Foundation Subscription Settings Service"}

if ($subscriptionSettingsService -eq $null) {
    Write-Warning "Unable to locate the subscription settings service! Did you run the configuration wizard to create a new farm?"
} else {
    if($subscriptionSettingsService.Status -ne "Online") { 
        Write-Host "Starting Subscription Settings Service" 
        Start-SPServiceInstance $subscriptionSettingsService | Out-Null
    } 

    # wait for subscription service to start" 
    while ($service.Status -ne "Online") {
        # delay 5 seconds then check to see if service has started
        sleep 5
        $service = Get-SPServiceInstance | where {$_.TypeName -like "Microsoft SharePoint Foundation Subscription Settings Service"}
    } 

    $subscriptionSettingsServiceApplicationName = "Site Subscription Settings Service Application"
    $subscriptionSettingsServiceApplication = Get-SPServiceApplication | where {$_.Name -eq $subscriptionSettingsServiceApplicationName} 

    # create an instance Subscription Service Application and proxy if they do not exist 
    if($subscriptionSettingsServiceApplication -eq $null) { 
        Write-Host "Creating Subscription Settings Service Application..." 
        $pool = Get-SPServiceApplicationPool "SharePoint Web Services Default" 

        if ($pool -eq $null) {
            Write-Warning "Unable to locate the SharePoint Web Services Default application pool. Make sure IIS is started. Subscription settings service application not created."
        } else {
            $subscriptionSettingsServiceDB = "Sharepoint_SiteSubscriptionSettingsServiceDB"
            $subscriptionSettingsServiceApplication = New-SPSubscriptionSettingsServiceApplication `
                                                        -ApplicationPool $pool `
                                                        -Name $subscriptionSettingsServiceApplicationName `
                                                        -DatabaseName $subscriptionSettingsServiceDB -ErrorAction Continue
            if ($subscriptionSettingsServiceApplication -eq $null) {
                Write-Warning "There was an error creating the subscription settings service application. Make sure that the SQL Server instance is started and that you are logged on as the administrator."
            } else {
                Write-Host "Creating Subscription Settings Service Application Proxy..." 
                $subscriptionSettingsServicApplicationProxy = New-SPSubscriptionSettingsServiceApplicationProxy `
                                                                -ServiceApplication $subscriptionSettingsServiceApplication
            }
        }
    }

    # assign name to default tenant to configure URL used to access web apps 
    Set-SPAppSiteSubscriptionName -Name "WingtipTenant" -Confirm:$false
}



Write-Host 
Read-Host -Prompt "Press ENTER to continue"