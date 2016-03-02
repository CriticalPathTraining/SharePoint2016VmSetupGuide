$snapin = Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue -PassThru

if ($snapin -eq $null) {
    Write-Error "Unable to load the Microsoft.SharePoint.PowerShell Snapin! Have you installed SharePoint?"
    return
}

# add SQL Server login for WINGTIP\SP_Workflow
# add this login to roles of securityadmin and dbcreator
$sql = "CREATE LOGIN [WINGTIP\SP_Workflow] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
        GO
        ALTER SERVER ROLE [securityadmin] ADD MEMBER [WINGTIP\SP_Workflow]
        GO
        ALTER SERVER ROLE [dbcreator] ADD MEMBER [WINGTIP\SP_Workflow]"

# invoke this SQL command
Write-Host "Granting SP_Workflow dbcreator and securityadmin rights..."
Invoke-Sqlcmd -ServerInstance "WINGTIPSERVER\SharePoint" -Query $sql

# determine path to CreateWorkflowFarmScript.ps1
$currentScriptPath = $MyInvocation.MyCommand.Path
$scriptFolder = Split-Path $currentScriptPath
$targetScriptPath = Join-Path $scriptFolder "\Script07_CreateWorkflowFarmScript.ps1"

Write-Host
Write-Host "Executing script $targetScriptPath using credentials of SP_Workflow"
Write-Host "This script will execute within its own window"

# Get the Farm Account Creds 
$serviceAccountName = "WINGTIP\SP_Workflow"
$serviceAccountPassword = "Password1"
$serviceAccountSecureStringPassword = ConvertTo-SecureString -String $serviceAccountPassword -AsPlainText -Force
$serviceAccountCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $serviceAccountName, $serviceAccountSecureStringPassword 

# Create a new process with UAC elevation 
Start-Process $PSHOME\powershell.exe `
                -Credential $serviceAccountCredentials `
                -ArgumentList "-Command Start-Process $PSHOME\powershell.exe -ArgumentList `"'$targetScriptPath'`" -Verb Runas" -Wait

Write-Host
Write-Host "Reverting back to identity of WINGTIP\Administrator"
Write-Host 

# register workflow farm with SharePoint farm
Write-Host "Registering new workflow farm with SharePoint farm to support SharePoint 2016 workflows"
Register-SPWorkflowService –SPSite "http://wingtipserver" –WorkflowHostUri "http://wingtipserver:12291" –AllowOAuthHttp


Write-Host 
Read-Host -Prompt "Press ENTER to continue"