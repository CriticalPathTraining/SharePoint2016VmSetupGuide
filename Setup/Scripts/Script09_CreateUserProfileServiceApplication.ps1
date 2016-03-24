Add-PSSnapin Microsoft.SharePoint.PowerShell

function Create-UserProfileServiceApplication {

    $service = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Service"}

    if ($service -eq $null) {
        Write-Warning "Unable to locate the user profile service! Did you run the configuration wizard to create a new farm?"
        return
    }
    if ($service.Status -ne "Online") {
        Write-Host "Starting User Profile Service instance" -NoNewline
        $service | Start-SPServiceInstance | Out-Null

        # ensure the service is online before attempting to add a svc app.
        while ($true) {
            Start-Sleep 2
            Write-Host "." -NoNewLine
            $svc = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Service"}
            if ($svc.Status -eq "Online") { break }
        }
        Write-Host
    }

    $serviceApplicationName = "User Profile Service Application"
    $serviceAppPoolName = "SharePoint Web Services Default"
    $server = "WingtipServer\SharePoint"
    $profileDBName = "SharePoint_UserProfileDB"
    $socialDBName = "SharePoint_UserProfileSocialDB"
    $profileSyncDBName = "SharePoint_UserProfileSyncDB"
    $mySiteHostLocation = "http://my.wingtip.com"
    $mySiteManagedPath = "personal"


    Write-Host "Checking to see if User Profile Service Application has already been created..." 
    $serviceApplication = Get-SPServiceApplication | where {$_.Name -eq $serviceApplicationName}
    if($serviceApplication -eq $null) {
        Write-Host "Creating the User Profile Service Application..."
        $serviceApplication = New-SPProfileServiceApplication `
                                    -Name $serviceApplicationName `
                                    -ApplicationPool $serviceAppPoolName `
                                    -ProfileDBName $profileDBName `
                                    -ProfileDBServer $server `
                                    -SocialDBName $socialDBName `
                                    -SocialDBServer $server `
                                    -ProfileSyncDBName $profileSyncDBName `
                                    -ProfileSyncDBServer $server `
                                    -MySiteHostLocation $mySiteHostLocation `
                                    -MySiteManagedPath $mySiteManagedPath `
                                    -SiteNamingConflictResolution None
    
        $serviceApplicationProxyName = "User Profile Service Application"
        Write-Host "Creating the User Profile Service Proxy..."
        $serviceApplicationProxy = New-SPProfileServiceApplicationProxy `
                                        -Name $serviceApplicationProxyName `
                                        -ServiceApplication $serviceApplication `
                                        -DefaultProxyGroup 
  
        Write-Host "User Profile Service Application and Proxy have been created by the SP_Farm account"
        Write-Host 
    }


    # Check to ensure it worked 
    Get-SPServiceApplication | ? {$_.TypeName -eq "User Profile Service Application"} 



}

function Start-UserProfileSynchronizationService {

    $svc = Get-SPServiceInstance | where {$_.TypeName -eq "User Profile Synchronization Service"}
    $app = Get-SPServiceApplication -Name "User Profile Service Application"

    if ($svc -eq $null) {
        Write-Warning "Unable to locate the user profile synchronization service! Did you run the configuration wizard to create a new farm?"
        return
    }
    if ($app -eq $null) {
        Write-Warning "Unable to locate the user profile service application!"
        return
    }
    if ($svc.Status -ne "Online") {
        Write-Host "Starting the User Profile Service Synchronization instance (cross your fingers)" -NoNewline
        $svc.Status = "Provisioning"
        $svc.IsProvisioned = $false
        $svc.UserProfileApplicationGuid = $app.Id
        $svc.Update()

        $app.SetSynchronizationMachine("WingtipServer", $svc.Id, "WINGTIP\SP_Farm", "Password1")
          
        $svc | Start-SPServiceInstance | Out-Null
        
        # ensure the service is online before attempting to add a svc app.
        # blocking on service start disable to reach end of script
        while ($true) {
            Start-Sleep 5
            Write-Host "." -NoNewLine
            $svc = Get-SPServiceInstance $svc.Id
            if ($svc.Status -eq "Online") { break }
        }

        Write-Host
    }
}

function Set-UPSConnectionPermission{
    $accountName = "WINGTIP\Administrator"
    Write-Host "Setting connection permissions for $accountName"

    $claimType = "http://schemas.microsoft.com/sharepoint/2009/08/claims/userlogonname"
    $claimValue = $accountName
    $claim = New-Object Microsoft.SharePoint.Administration.Claims.SPClaim($claimType, $claimValue, "http://www.w3.org/2001/XMLSchema#string", [Microsoft.SharePoint.Administration.Claims.SPOriginalIssuers]::Format("Windows"))
    $claim.ToEncodedString()
 
    $permission = [Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights]"FullControl"
 
    $SPAclAccessRule = [Type]"Microsoft.SharePoint.Administration.AccessControl.SPAclAccessRule``1"
    $specificSPAclAccessRule = $SPAclAccessRule.MakeGenericType([Type]"Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights")
    $ctor = $SpecificSPAclAccessRule.GetConstructor(@([Type]"Microsoft.SharePoint.Administration.Claims.SPClaim",[Type]"Microsoft.SharePoint.Administration.AccessControl.SPIisWebServiceApplicationRights"))
    $accessRule = $ctor.Invoke(@([Microsoft.SharePoint.Administration.Claims.SPClaim]$claim, $permission))
 
    $ups = Get-SPServiceApplication | ? { $_.TypeName -eq 'User Profile Service Application' }
    if ($ups -eq $null) {
        Write-Warning "Unable to locate the user profile service application!"
        return
    }

    $accessControl = $ups.GetAccessControl()
    $accessControl.AddAccessRule($accessRule)
    $ups.SetAccessControl($accessControl)
    $ups.Update()
}

function Foo($profileServiceId) {
    Add-SPProfileSyncConnection -ProfileServiceApplication $profileServiceId -ConnectionForestName "wingtip.com"-ConnectionDomain "WINGTIP" -ConnectionUserName "Wingtip Users" -ConnectionPassword convertto-securestring "Password1" -asplaintext -force -ConnectionSynchronizationOU "OU=Wingtip Users,DC=wingtip,DC=com"
}

Create-UserProfileServiceApplication

Start-UserProfileSynchronizationService

Set-UPSConnectionPermission

Write-Host