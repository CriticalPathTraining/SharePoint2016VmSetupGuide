cls

function Create-SharePointServiceAccounts {

    Write-Host "Creating Wingtip service accounts in Active Directory..."

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

    # create account for SQL Server worker process identity
    $sqlUserName = "SQL_Server"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $sqlUserName -Name $sqlUserName -DisplayName $sqlUserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
    $sqlUser = Get-ADUser -Filter "samAccountName -eq 'SQL_Server'"
    Add-ADGroupMember -Identity "Administrators" -Members $sqlUser


    # create farm service account 
    $UserName = "SP_Farm"
    Write-Host (" - adding User: {0}" -f $UserName)
    New-ADUser -Path $ouWingtipServiceAccountsPath -SamAccountName $UserName -Name $UserName -DisplayName $UserName -AccountPassword $UserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true


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

# create active directory accounts for SharePoint service accounts
Create-SharePointServiceAccounts

Write-Host
Write-Host "Wingtip service accounts have been created"
Write-Host